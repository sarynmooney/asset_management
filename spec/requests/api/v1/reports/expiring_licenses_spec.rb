# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v1/reports/expiring_licenses", type: :request do
  it "returns 200 with default days=30" do
    company = create(:company, name: "Acme Corp")
    create(:contact, company: company, email: "john@acme.com", role: "primary")
    asset = create(:asset, company: company, name: "SERVER-01", asset_type: "server")
    create(:software_license, asset: asset, software_name: "Windows Server 2019", expiration_date: 14.days.from_now.to_date)

    get "/api/v1/reports/expiring_licenses"

    expect(response).to have_http_status(:ok)
    json = response.parsed_body
    expect(json).to have_key("expiring_licenses")
    expect(json).to have_key("summary")
    expect(json["summary"]).to include("total_expiring", "by_software")
    expect(json["expiring_licenses"].length).to eq(1)
    license_json = json["expiring_licenses"].first
    expect(license_json).to include("software_name" => "Windows Server 2019", "company_contact" => "john@acme.com")
    expect(license_json["asset"]).to include("name" => "SERVER-01", "asset_type" => "server", "company_name" => "Acme Corp")
    expect(license_json).to have_key("days_until_expiration")
    expect(license_json).to have_key("expiration_date")
  end

  it "returns 200 with custom days parameter" do
    company = create(:company)
    create(:contact, company: company, role: "primary")
    asset = create(:asset, company: company)
    create(:software_license, asset: asset, software_name: "Office 365", expiration_date: 45.days.from_now.to_date)

    get "/api/v1/reports/expiring_licenses", params: { days: 60 }

    expect(response).to have_http_status(:ok)
    json = response.parsed_body
    expect(json["expiring_licenses"].length).to eq(1)
    expect(json["expiring_licenses"].first["software_name"]).to eq("Office 365")
  end

  it "orders by expiration_date ascending" do
    company = create(:company)
    create(:contact, company: company, role: "primary")
    asset = create(:asset, company: company)
    create(:software_license, asset: asset, software_name: "Late", expiration_date: 30.days.from_now.to_date)
    create(:software_license, asset: asset, software_name: "Early", expiration_date: 5.days.from_now.to_date)

    get "/api/v1/reports/expiring_licenses", params: { days: 60 }

    expect(response).to have_http_status(:ok)
    names = response.parsed_body["expiring_licenses"].map { |l| l["software_name"] }
    expect(names).to eq(["Early", "Late"])
  end

  it "includes already expired licenses with negative days_until_expiration" do
    company = create(:company)
    create(:contact, company: company, role: "primary")
    asset = create(:asset, company: company)
    create(:software_license, asset: asset, software_name: "Expired", expiration_date: 5.days.ago.to_date)

    get "/api/v1/reports/expiring_licenses", params: { days: 30 }

    expect(response).to have_http_status(:ok)
    json = response.parsed_body
    expect(json["expiring_licenses"].length).to eq(1)
    expect(json["expiring_licenses"].first["days_until_expiration"]).to eq(-5)
    expect(json["summary"]["total_expiring"]).to eq(1)
  end

  it "returns by_software count grouped by software_name" do
    company = create(:company)
    create(:contact, company: company, role: "primary")
    asset1 = create(:asset, company: company)
    asset2 = create(:asset, company: company)
    create(:software_license, asset: asset1, software_name: "Windows", expiration_date: 10.days.from_now.to_date)
    create(:software_license, asset: asset2, software_name: "Windows", expiration_date: 20.days.from_now.to_date)
    create(:software_license, asset: asset1, software_name: "Office", expiration_date: 15.days.from_now.to_date)

    get "/api/v1/reports/expiring_licenses", params: { days: 30 }

    expect(response).to have_http_status(:ok)
    by_software = response.parsed_body["summary"]["by_software"]
    expect(by_software["Windows"]).to eq(2)
    expect(by_software["Office"]).to eq(1)
  end
end
