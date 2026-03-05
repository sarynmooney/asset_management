# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v1/reports/maintenance_costs", type: :request do
  describe "when dates are invalid or missing" do
    it "returns 400 when start_date is missing" do
      get "/api/v1/reports/maintenance_costs", params: { end_date: "2025-12-31" }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]).to include("start_date and end_date are required")
    end

    it "returns 400 when end_date is missing" do
      get "/api/v1/reports/maintenance_costs", params: { start_date: "2025-01-01" }

      expect(response).to have_http_status(:bad_request)
    end

    it "returns 400 when start_date > end_date" do
      get "/api/v1/reports/maintenance_costs", params: { start_date: "2025-12-31", end_date: "2025-01-01" }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]).to eq("start_date must be on or before end_date")
    end

    it "returns 400 when date format is invalid" do
      get "/api/v1/reports/maintenance_costs", params: { start_date: "not-a-date", end_date: "2025-01-01" }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "when date range is valid" do
    it "returns 200 with date_range, summary, by_company, by_asset_type" do
      company = create(:company, name: "Acme Corp")
      create(:contact, company: company, role: "primary")
      asset1 = create(:asset, company: company, asset_type: "server")
      asset2 = create(:asset, company: company, asset_type: "workstation")
      create(:maintenance_record, asset: asset1, performed_at: 1.week.ago, cost: 300.00)
      create(:maintenance_record, asset: asset1, performed_at: 2.weeks.ago, cost: 200.00)
      create(:maintenance_record, asset: asset2, performed_at: 10.days.ago, cost: 100.00)

      start_date = 3.weeks.ago.to_date.to_s
      end_date = Date.current.to_s
      get "/api/v1/reports/maintenance_costs", params: { start_date: start_date, end_date: end_date }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["date_range"]["start_date"]).to eq(start_date)
      expect(json["date_range"]["end_date"]).to eq(end_date)

      summary = json["summary"]
      expect(summary["total_cost"].to_f).to eq(600.0)
      expect(summary["total_maintenance_count"]).to eq(3)
      expect(summary["avg_cost_per_maintenance"].to_f).to eq(200.0)

      by_company = json["by_company"]
      expect(by_company).to be_an(Array)
      expect(by_company.length).to eq(1)
      company_row = by_company.first
      expect(company_row["company_name"]).to eq("Acme Corp")
      expect(company_row["total_cost"].to_f).to eq(600.0)
      expect(company_row["maintenance_count"]).to eq(3)
      expect(company_row["assets_serviced"]).to eq(2)
      expect(company_row["avg_cost_per_service"].to_f).to eq(200.0)

      by_asset_type = json["by_asset_type"]
      expect(by_asset_type["server"]["total_cost"].to_f).to eq(500.0)
      expect(by_asset_type["server"]["maintenance_count"]).to eq(2)
      expect(by_asset_type["workstation"]["total_cost"].to_f).to eq(100.0)
      expect(by_asset_type["workstation"]["maintenance_count"]).to eq(1)
    end

    it "orders by_company by total_cost descending" do
      company_a = create(:company, name: "A Corp")
      company_b = create(:company, name: "B Corp")
      create(:contact, company: company_a, role: "primary")
      create(:contact, company: company_b, role: "primary")
      asset_a = create(:asset, company: company_a)
      asset_b = create(:asset, company: company_b)
      create(:maintenance_record, asset: asset_a, performed_at: 1.week.ago, cost: 100.00)
      create(:maintenance_record, asset: asset_b, performed_at: 1.week.ago, cost: 500.00)

      get "/api/v1/reports/maintenance_costs", params: { start_date: 2.weeks.ago.to_date.to_s, end_date: Date.current.to_s }

      expect(response).to have_http_status(:ok)
      names = response.parsed_body["by_company"].map { |r| r["company_name"] }
      expect(names).to eq(["B Corp", "A Corp"])
    end

    it "only includes companies that had maintenance in the period" do
      company_with = create(:company, name: "With Maint")
      company_without = create(:company, name: "Without Maint")
      create(:contact, company: company_with, role: "primary")
      create(:contact, company: company_without, role: "primary")
      asset = create(:asset, company: company_with)
      create(:asset, company: company_without)
      create(:maintenance_record, asset: asset, performed_at: 1.week.ago, cost: 50.00)

      get "/api/v1/reports/maintenance_costs", params: { start_date: 2.weeks.ago.to_date.to_s, end_date: Date.current.to_s }

      expect(response).to have_http_status(:ok)
      by_company = response.parsed_body["by_company"]
      expect(by_company.length).to eq(1)
      expect(by_company.first["company_name"]).to eq("With Maint")
    end

    it "excludes maintenance outside the date range" do
      company = create(:company)
      create(:contact, company: company, role: "primary")
      asset = create(:asset, company: company)
      create(:maintenance_record, asset: asset, performed_at: 1.week.ago, cost: 100.00)
      create(:maintenance_record, asset: asset, performed_at: 2.months.ago, cost: 999.00)

      get "/api/v1/reports/maintenance_costs", params: { start_date: 2.weeks.ago.to_date.to_s, end_date: Date.current.to_s }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["summary"]["total_cost"].to_f).to eq(100.0)
      expect(response.parsed_body["summary"]["total_maintenance_count"]).to eq(1)
    end
  end
end
