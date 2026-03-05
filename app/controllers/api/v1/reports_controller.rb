# frozen_string_literal: true

class Api::V1::ReportsController < ApplicationController
  def company_comparison
    company_ids = Array(params[:company_ids]).map(&:to_i).reject(&:zero?)
    if company_ids.empty?
      return render json: { error: "company_ids is required" }, status: :bad_request
    end
    if company_ids.size > 50
      return render json: { error: "at most 50 company_ids allowed" }, status: :bad_request
    end

    companies = Company.where(id: company_ids).order(:name)
    rows = companies.map { |c| company_comparison_row(c) }
    render json: {
      companies: rows,
      totals: company_comparison_totals(rows)
    }
  end

  def expiring_licenses
    days = (params[:days].presence || 30).to_i
    end_date = Date.current + days
    licenses = SoftwareLicense
      .joins(asset: :company)
      .where("software_licenses.expiration_date <= ?", end_date)
      .order(expiration_date: :asc)
      .includes(asset: :company)

    expiring_list = licenses.map { |license| expiring_license_row(license) }
    by_software = expiring_list.group_by { |h| h[:software_name] }.transform_values(&:count)

    render json: {
      expiring_licenses: expiring_list,
      summary: {
        total_expiring: expiring_list.size,
        by_software: by_software
      }
    }
  end

  def maintenance_costs
    start_date = parse_date(params[:start_date])
    end_date = parse_date(params[:end_date])
    if start_date.nil? || end_date.nil?
      return render json: { error: "start_date and end_date are required (YYYY-MM-DD)" }, status: :bad_request
    end
    if start_date > end_date
      return render json: { error: "start_date must be on or before end_date" }, status: :bad_request
    end

    range = start_date.beginning_of_day..end_date.end_of_day
    records = MaintenanceRecord
      .joins(asset: :company)
      .where(performed_at: range)

    summary = {
      total_cost: records.sum(:cost).to_f,
      total_maintenance_count: records.count,
      avg_cost_per_maintenance: records.count.positive? ? (records.sum(:cost).to_f / records.count).round(2) : 0
    }

    by_company = maintenance_by_company(records)
    by_asset_type = maintenance_by_asset_type(records)

    render json: {
      date_range: { start_date: start_date.to_s, end_date: end_date.to_s },
      summary: summary,
      by_company: by_company,
      by_asset_type: by_asset_type
    }
  end

  private

  def company_comparison_row(company)
    assets = company.assets
    assets_with_date = assets.where.not(purchase_date: nil)
    avg_age = if assets_with_date.exists?
      ages = assets_with_date.pluck(:purchase_date).map { |d| (Date.current - d).to_f / 365.25 }
      (ages.sum / ages.size).round(1)
    else
      nil
    end

    maintenance_ytd = MaintenanceRecord
      .joins(asset: :company)
      .where(companies: { id: company.id })
      .where(performed_at: Date.current.beginning_of_year..Date.current.end_of_year.end_of_day)
      .sum(:cost)
      .to_f

    expiring_count = SoftwareLicense
      .joins(asset: :company)
      .where(companies: { id: company.id })
      .where(expiration_date: Date.current..60.days.from_now.to_date)
      .count

    last_maint = MaintenanceRecord
      .joins(asset: :company)
      .where(companies: { id: company.id })
      .order(performed_at: :desc)
      .pick(:performed_at)

    {
      id: company.id,
      name: company.name,
      total_assets: assets.count,
      avg_asset_age_years: avg_age,
      maintenance_cost_ytd: maintenance_ytd,
      expiring_licenses_count: expiring_count,
      last_maintenance_date: last_maint&.to_date&.to_s
    }
  end

  def company_comparison_totals(rows)
    {
      total_assets: rows.sum { |r| r[:total_assets] },
      total_maintenance_cost: rows.sum { |r| r[:maintenance_cost_ytd] }.round(2),
      total_expiring_licenses: rows.sum { |r| r[:expiring_licenses_count] }
    }
  end

  def expiring_license_row(license)
    company = license.asset.company
    contact = company.contacts.find_by(role: "primary") || company.contacts.order(:id).first
    {
      id: license.id,
      software_name: license.software_name,
      license_key: license.license_key,
      expiration_date: license.expiration_date.to_s,
      days_until_expiration: (license.expiration_date - Date.current).to_i,
      asset: {
        id: license.asset.id,
        name: license.asset.name,
        asset_type: license.asset.asset_type,
        company_name: company.name
      },
      company_contact: contact&.email
    }
  end

  def parse_date(value)
    return nil if value.blank?
    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def maintenance_by_company(records_scope)
    records_scope
      .group("companies.id", "companies.name")
      .select(
        "companies.id AS company_id",
        "companies.name AS company_name",
        "SUM(maintenance_records.cost) AS total_cost",
        "COUNT(maintenance_records.id) AS maintenance_count",
        "COUNT(DISTINCT maintenance_records.asset_id) AS assets_serviced"
      )
      .order("total_cost DESC")
      .map do |row|
        count = row.maintenance_count.to_i
        {
          company_id: row.company_id,
          company_name: row.company_name,
          total_cost: row.total_cost.to_f.round(2),
          maintenance_count: count,
          assets_serviced: row.assets_serviced.to_i,
          avg_cost_per_service: count.positive? ? (row.total_cost.to_f / count).round(2) : 0
        }
      end
  end

  def maintenance_by_asset_type(records_scope)
    records_scope
      .joins(:asset)
      .group("assets.asset_type")
      .select(
        "assets.asset_type AS asset_type",
        "SUM(maintenance_records.cost) AS total_cost",
        "COUNT(maintenance_records.id) AS maintenance_count"
      )
      .map { |row| [row.asset_type, { total_cost: row.total_cost.to_f.round(2), maintenance_count: row.maintenance_count.to_i }] }
      .to_h
  end
end
