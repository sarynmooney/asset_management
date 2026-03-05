# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v1/reports/company_comparison", type: :request do
  describe "when company_ids is missing or empty" do
    it "returns 400 when no company_ids" do
      get "/api/v1/reports/company_comparison"

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]).to eq("company_ids is required")
    end

    it "returns 400 when company_ids is empty array" do
      get "/api/v1/reports/company_comparison", params: { company_ids: [] }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]).to eq("company_ids is required")
    end
  end

  describe "when company_ids has more than 50 ids" do
    it "returns 400" do
      get "/api/v1/reports/company_comparison", params: { company_ids: (1..51).to_a }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]).to eq("at most 50 company_ids allowed")
    end
  end

  describe "when company_ids is valid" do
    it "returns 200 with companies and totals, skips non-existent ids, orders by name" do
      acme = create(:company, name: "Acme Corp")
      techstart = create(:company, name: "TechStart Inc")
      create(:contact, company: acme, role: "primary")
      create(:contact, company: techstart, role: "primary")
      create(:asset, company: acme, purchase_date: 2.years.ago.to_date)
      create(:asset, company: acme, purchase_date: 3.years.ago.to_date)
      create(:asset, company: techstart, purchase_date: 1.year.ago.to_date)
      create(:maintenance_record, asset: acme.assets.first, performed_at: 1.week.ago, cost: 100.50)
      create(:maintenance_record, asset: techstart.assets.first, performed_at: 2.weeks.ago, cost: 50.00)
      create(:software_license, asset: acme.assets.first, expiration_date: 30.days.from_now.to_date)
      create(:software_license, asset: techstart.assets.first, expiration_date: 45.days.from_now.to_date)

      get "/api/v1/reports/company_comparison", params: { company_ids: [techstart.id, acme.id, 99999] }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to have_key("companies")
      expect(json).to have_key("totals")

      companies = json["companies"]
      expect(companies.size).to eq(2)
      expect(companies.map { |c| c["name"] }).to eq(["Acme Corp", "TechStart Inc"])

      acme_row = companies.find { |c| c["id"] == acme.id }
      expect(acme_row["total_assets"]).to eq(2)
      expect(acme_row["avg_asset_age_years"]).to be_within(0.1).of(2.5)
      expect(acme_row["maintenance_cost_ytd"].to_f).to eq(100.5)
      expect(acme_row["expiring_licenses_count"]).to eq(1)
      expect(acme_row["last_maintenance_date"]).to be_present

      techstart_row = companies.find { |c| c["id"] == techstart.id }
      expect(techstart_row["total_assets"]).to eq(1)
      expect(techstart_row["maintenance_cost_ytd"].to_f).to eq(50.0)
      expect(techstart_row["expiring_licenses_count"]).to eq(1)

      totals = json["totals"]
      expect(totals["total_assets"]).to eq(3)
      expect(totals["total_maintenance_cost"]).to eq(150.5)
      expect(totals["total_expiring_licenses"]).to eq(2)
    end

    it "returns last_maintenance_date as null when company has no maintenance" do
      company = create(:company, name: "No Maint Corp")
      create(:contact, company: company, role: "primary")
      create(:asset, company: company)

      get "/api/v1/reports/company_comparison", params: { company_ids: [company.id] }

      expect(response).to have_http_status(:ok)
      row = response.parsed_body["companies"].first
      expect(row["last_maintenance_date"]).to be_nil
    end

    it "returns avg_asset_age_years as null when no assets have purchase_date" do
      company = create(:company, name: "No Dates")
      create(:contact, company: company, role: "primary")
      create(:asset, company: company, purchase_date: nil)

      get "/api/v1/reports/company_comparison", params: { company_ids: [company.id] }

      expect(response).to have_http_status(:ok)
      row = response.parsed_body["companies"].first
      expect(row["avg_asset_age_years"]).to be_nil
    end
  end
end
