class AddPriceAtBookingToAppointmentServices < ActiveRecord::Migration[8.1]
  def change
    add_column :appointment_services, :price_at_booking, :decimal, precision: 10, scale: 2
  end
end
