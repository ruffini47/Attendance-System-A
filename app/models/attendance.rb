class Attendance < ApplicationRecord
  belongs_to :user
  
  enum  instructor_confirmation: { "なし" => 0, "申請中" => 1, "承認" => 2, "否認" => 3 }
  
  validates :worked_on, presence: true
  validates :note, length: { maximum: 50 }

  # 出勤時間のみが存在し、退勤時間が存在しない場合、無効
  validate :started_at_is_invalid_without_a_finished_at
  
  # 出勤時間が存在しない場合、退勤時間は無効
  validate :finished_at_is_invalid_without_a_started_at

  # 出勤・退勤時間どちらも存在するとき、出勤時間よりも早い退勤時間は無効
  validate :temp_after_change_start_time_than_temp_after_change_end_time_fast_if_invalid
  
  def started_at_is_invalid_without_a_finished_at
    errors.add(:finished_at, "が必要です") if started_at.present? && finished_at.blank?
  end
  
  def finished_at_is_invalid_without_a_started_at
    errors.add(:started_at, "が必要です") if started_at.blank? && finished_at.present?
  end
  
  def temp_after_change_start_time_than_temp_after_change_end_time_fast_if_invalid
    if temp_after_change_start_time.present? && temp_after_change_end_time.present?
      errors.add(:temp_after_change_start_time, "より早い退勤時間は無効です") if temp_after_change_start_time > temp_after_change_end_time
    end
  end
end
