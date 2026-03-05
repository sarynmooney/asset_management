# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v1/companies/:id/dashboard", type: :request do
  describe "when the company does not exist" do
    it "returns 404" do
      get "/api/v1/companies/99999/dashboard"

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["error"]).to eq("Company not found")
    end
  end

  describe "when the company exists" do
    it "returns 200 and the dashboard payload" do
      company = create(:company, name: "Acme Corp")
      create(:contact, company: company, name: "John Smith", email: "john@acme.com", role: "primary")
      asset = create(:asset, company: company, name: "SERVER-01", asset_type: "server")
      create(:maintenance_record, asset: asset, description: "Replaced hard drive", performed_at: 1.week.ago, cost: 250.00)
      create(:software_license, asset: asset, software_name: "Windows Server 2019", expiration_date: 33.days.from_now.to_date)

      get "/api/v1/companies/#{company.id}/dashboard"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to have_key("company")

      company_json = json["company"]
      expect(company_json["id"]).to eq(company.id)
      expect(company_json["name"]).to eq("Acme Corp")
      expect(company_json["total_assets"]).to eq(1)
      expect(company_json["assets_by_type"]).to eq("server" => 1)
      expect(company_json["total_maintenance_cost_ytd"].to_f).to eq(250.0)
      expect(company_json["primary_contact"]).to include(
        "name" => "John Smith",
        "email" => "john@acme.com",
        "role" => "primary"
      )

      expect(company_json["expiring_licenses"]).to be_an(Array)
      expect(company_json["expiring_licenses"].length).to eq(1)
      expect(company_json["expiring_licenses"].first).to include(
        "software_name" => "Windows Server 2019",
        "asset_name" => "SERVER-01"
      )
      expect(company_json["expiring_licenses"].first).to have_key("expiration_date")
      expect(company_json["expiring_licenses"].first["days_until_expiration"]).to eq(33)

      expect(company_json["recent_maintenance"]).to be_an(Array)
      expect(company_json["recent_maintenance"].length).to eq(1)
      expect(company_json["recent_maintenance"].first).to include(
        "asset_name" => "SERVER-01",
        "description" => "Replaced hard drive"
      )
      expect(company_json["recent_maintenance"].first["cost"].to_f).to eq(250.0)
      expect(company_json["recent_maintenance"].first).to have_key("performed_at")
    end
  end
end
