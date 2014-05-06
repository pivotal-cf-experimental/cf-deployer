class SpiffChecker
  def self.spiff_present?
    system('which spiff')
    $? == 0
  end
end
