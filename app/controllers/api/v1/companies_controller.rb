class Api::V1::CompaniesController < ApplicationController
  def dashboard
    company = Company.find(params[:id])
    render json: dashboard_payload(company)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Company not found" }, status: :not_found
  end

  private

  def dashboard_payload(company)
    {
      company: {
        id: company.id,
        name: company.name,
        total_assets: company.assets.count,
        assets_by_type: company.assets.group(:asset_type).count,
        total_maintenance_cost_ytd: total_maintenance_cost_ytd(company),
        expiring_licenses: expiring_licenses_for(company),
        recent_maintenance: recent_maintenance_for(company),
        primary_contact: primary_contact_for(company)
      }
    }
  end

  def total_maintenance_cost_ytd(company)
    MaintenanceRecord
      .joins(asset: :company)
      .where(companies: { id: company.id })
      .where(performed_at: Date.current.beginning_of_year..Date.current.end_of_year.end_of_day)
      .sum(:cost)
  end

  def expiring_licenses_for(company)
    range = Date.current..60.days.from_now.to_date
    SoftwareLicense
      .joins(asset: :company)
      .where(companies: { id: company.id })
      .where(expiration_date: range)
      .order(expiration_date: :asc)
      .limit(10)
      .includes(:asset)
      .map do |license|
        {
          software_name: license.software_name,
          expiration_date: license.expiration_date.to_s,
          asset_name: license.asset.name,
          days_until_expiration: (license.expiration_date - Date.current).to_i
        }
      end
  end

  def recent_maintenance_for(company)
    MaintenanceRecord
      .joins(asset: :company)
      .where(companies: { id: company.id })
      .order(performed_at: :desc)
      .limit(5)
      .includes(:asset)
      .map do |record|
        {
          asset_name: record.asset.name,
          description: record.description,
          performed_at: record.performed_at.iso8601,
          cost: record.cost.to_f
        }
      end
  end

  def primary_contact_for(company)
    contact = company.contacts.find_by(role: "primary") || company.contacts.order(:id).first
    return nil if contact.blank?

    {
      name: contact.name,
      email: contact.email,
      role: contact.role
    }
  end
end
