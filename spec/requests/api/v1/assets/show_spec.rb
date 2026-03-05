# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v1/assets/:id", type: :request do
  describe "when the asset does not exist" do
    it "returns 404" do
      get "/api/v1/assets/99999"

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["error"]).to eq("Asset not found")
    end
  end

  describe "when the asset exists" do
    it "returns 200 and the asset detail payload" do
      company = create(:company, name: "Acme Corp")
      create(:contact, company: company, name: "John Smith", email: "john@acme.com", role: "primary")
      asset = create(:asset, company: company, name: "SERVER-01", asset_type: "server", serial_number: "SN123456", purchase_date: 2.years.ago.to_date)
      create(:maintenance_record, asset: asset, description: "Replaced hard drive", performed_at: 1.week.ago, cost: 250.00)
      create(:software_license, asset: asset, software_name: "Windows Server 2019", expiration_date: 33.days.from_now.to_date)
      author = create(:user, name: "Tech Support")
      create(:note, asset: asset, author: author, content: "Disk space running low on C: drive")

      get "/api/v1/assets/#{asset.id}"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to have_key("asset")

      asset_json = json["asset"]
      expect(asset_json["id"]).to eq(asset.id)
      expect(asset_json["name"]).to eq("SERVER-01")
      expect(asset_json["asset_type"]).to eq("server")
      expect(asset_json["serial_number"]).to eq("SN123456")
      expect(asset_json["company_name"]).to eq("Acme Corp")
      expect(asset_json["company_contact_email"]).to eq("john@acme.com")
      expect(asset_json["maintenance_count"]).to eq(1)
      expect(asset_json["total_maintenance_cost"].to_f).to eq(250.0)
      expect(asset_json["last_maintenance_date"]).to be_present
      expect(asset_json["last_maintenance_date"]).to match(/\A\d{4}-\d{2}-\d{2}\z/)

      expect(asset_json["software_licenses"]).to be_an(Array)
      expect(asset_json["software_licenses"].length).to eq(1)
      license_json = asset_json["software_licenses"].first
      expect(license_json).to include("software_name" => "Windows Server 2019", "expired" => false)
      expect(license_json["days_until_expiration"]).to eq(33)
      expect(license_json).to have_key("expiration_date")

      expect(asset_json["recent_notes"]).to be_an(Array)
      expect(asset_json["recent_notes"].length).to eq(1)
      note_json = asset_json["recent_notes"].first
      expect(note_json).to include("content" => "Disk space running low on C: drive", "author_name" => "Tech Support")
      expect(note_json).to have_key("id")
      expect(note_json).to have_key("created_at")
    end

    it "returns last_maintenance_date as null when asset has no maintenance records" do
      company = create(:company)
      create(:contact, company: company, role: "primary")
      asset = create(:asset, company: company)

      get "/api/v1/assets/#{asset.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("asset", "last_maintenance_date")).to be_nil
    end
  end
end
