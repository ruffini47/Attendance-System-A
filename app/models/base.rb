class Base < ApplicationRecord
  validates :number, presence: true, length: { maximum: 10 }
  validates :name, presence: true, length: { maximum: 20 }
  validates :attendance_type, presence: true, length: { maximum: 10 }
end
