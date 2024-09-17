# freeze_string_literal: true

# Provides Turnitin integration functionality for TaskDefinitions
module TaskDefinitionTiiModule
  # Check if document and has tii check requested
  def use_tii?(idx, upload_requirements_data = upload_requirements)
    return false unless is_document?(idx) && upload_requirements_data[idx].key?('tii_check')

    [true, 1, 'true'].include?(upload_requirements_data[idx]['tii_check'])
  end

  def tii_match_pct(idx)
    return 35 unless use_tii?(idx) && upload_requirements[idx].key?('tii_pct')

    upload_requirements[idx]['tii_pct'].to_i
  end

  # Does the task definition have any Turnitin checks?
  #
  # @return [Boolean] true if there are any Turnitin checks
  def tii_checks?
    TurnItIn.enabled? &&
      !upload_requirements.empty? &&
      ((0..upload_requirements.length - 1).map { |i| use_tii?(i) }.inject(:|) || false)
  end

  def had_tii_checks_before_last_save?
    TurnItIn.enabled? &&
      upload_requirements_before_last_save.present? &&
      !upload_requirements_before_last_save.empty? &&
      ((0..upload_requirements_before_last_save.length - 1).map { |i| use_tii?(i, upload_requirements_before_last_save) }.inject(:|) || false)
  end

  # Send all doc and docx files from the task resources to turn it in
  # as group attachments.
  def send_group_attachments_to_tii
    return if tii_group_id.blank?
    return unless has_task_resources?

    count = 0

    # loop through files in the task resources zip file
    Zip::File.open(task_resources) do |zip_file|
      zip_file.each do |entry|
        next unless entry.file?
        next unless entry.name.end_with?('.doc', '.docx')
        next if entry.name.include?('__MACOSX')
        next if entry.size < 50

        # TODO: This is a hack as TII limits the number of attachments to 3
        #       We need to merge documents into a single file...
        count += 1
        break if count > 3

        TiiGroupAttachment.find_or_create_from_task_definition(self, entry.name)
      end
    end
  end

  # Create or get the group for a task definition. The "group" is the Turn It In equivalent of an assignment.
  #
  # @param task_def [TaskDefinition] the task definition to create or get the group for
  # @return [TCAClient::Group] the group for the task definition
  def create_or_get_tii_group
    # if there is no group id, create one (but not register with tii)
    if self.tii_group_id.blank?
      self.tii_group_id = SecureRandom.uuid
      self.save
    end

    TCAClient::Group.new(
      id: self.tii_group_id,
      name: self.detailed_name,
      type: 'ASSIGNMENT'
    )
  end

  # If we added tii checks, then upload associated attachment files if needed
  def check_and_update_tii_status
    return unless tii_checks?
    return if had_tii_checks_before_last_save?

    # Make sure that we have a group context
    TurnItIn.create_or_get_group_context(unit)

    if tii_group_id.present?
      # We already have the group - so just create/send the attachments
      send_group_attachments_to_tii
    else
      # Trigger the update - which creates action if needed
      action = TiiActionUpdateTiiGroup.find_or_create_by(entity: self)
      action.params = { add_group_attachment: true }
      action.perform
    end
  end

  def update_tii_group
    return if tii_group_id.blank?

    action = TiiActionUpdateTiiGroup.find_or_create_by(entity: self)
    action.params = { update_due_date: true }
    action.perform
  end
end
