module ActiveRecordHooks
  def self.valid?(target)
    target.valid?;
  end
  def self.save(target)
    target.save;
  end
end
