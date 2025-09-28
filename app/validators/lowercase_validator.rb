class LowercaseValidator < ActiveModel::EachValidator
  REGEXP = /\A[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}\z/

  def validate_each(record, attribute, value)
    return if value&.match?(REGEXP)
    record.errors.add(attribute, options[:message] || "は小文字のみ・空白なしで入力してください")
  end
end
