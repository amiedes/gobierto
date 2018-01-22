# frozen_string_literal: true
#
module GobiertoPeople
  module MicrosoftExchange
    class CalendarIntegration

      attr_reader :person, :site, :configuration

      TARGET_CALENDAR_NAME = 'gobierto'

      def self.sync_person_events(person)
        new(person).sync
      end

      def sync
        Rails.logger.info "#{log_preffix} Syncing events for #{person.name} (id: #{person.id})"

        calendar_items = get_calendar_items

        mark_unreceived_events_as_drafts(calendar_items)

        Array(calendar_items).each do |item|
          sync_event(item)
        end
      rescue ::Errno::EADDRNOTAVAIL, ::SocketError, ::ArgumentError, ::Addressable::URI::InvalidURIError
        Rails.logger.info "#{log_preffix} Invalid endpoint address for #{person.name} (id: #{person.id}): #{Exchanger.config.endpoint}"
      rescue ::HTTPClient::ConnectTimeoutError
        Rails.logger.info "#{log_preffix} Timeout error for #{person.name} (id: #{person.id}): #{Exchanger.config.endpoint}"
      end

      private

      def initialize(person)
        @person = person
        @site = person.site
        @configuration = ::GobiertoCalendars::MicrosoftExchangeCalendarConfiguration.find_by(collection_id: person.calendar.id)

        Exchanger.configure do |config|
          config.endpoint = configuration.microsoft_exchange_url
          config.username = configuration.microsoft_exchange_usr
          config.password = ::SecretAttribute.decrypt(configuration.microsoft_exchange_pwd)
          config.debug    = false
          config.insecure_ssl = true
          config.ssl_version  = :TLSv1
        end
      end

      def get_calendar_items
        root_folder = Exchanger::Folder.find(:calendar)

        log_missing_folder_error('root') and return if root_folder.nil?

        target_folder = root_folder.folders.find { |folder| folder.display_name == TARGET_CALENDAR_NAME }

        log_missing_folder_error(TARGET_CALENDAR_NAME) and return if target_folder.nil?

        target_folder.expanded_items(start_date: GobiertoCalendars.sync_range_start, end_date: GobiertoCalendars.sync_range_end)
      end

      def sync_event(item)
        filter_result = GobiertoCalendars::FilteringRuleApplier.filter({
          title: item.subject,
          description: "" # TODO: https://github.com/PopulateTools/gobierto/issues/1127
        }, configuration.filtering_rules)

        filter_result = GobiertoCalendars::FilteringRuleApplier::REMOVE if is_private?(item)

        state = filter_result == GobiertoCalendars::FilteringRuleApplier::CREATE_PENDING ?
          GobiertoCalendars::Event.states[:pending] :
          GobiertoCalendars::Event.states[:published]

        event_params = {
          starts_at: item.start,
          ends_at: item.end,
          state: state,
          external_id: item.id,
          title: item.subject,
          site_id: site.id,
          person_id: person.id
        }

        if item.location.present?
          event_params.merge!(locations_attributes: { "0" => { name: item.location } })
        else
          event_params.merge!(locations_attributes: { "0" => { "_destroy" => "1" } })
        end

        if filter_result == GobiertoCalendars::FilteringRuleApplier::REMOVE
          GobiertoPeople::PersonEventForm.new(event_params).destroy
        else
          GobiertoPeople::PersonEventForm.new(event_params).save
        end
      end

      def is_private?(calendar_item)
        %w( Private ).include?(calendar_item.sensitivity)
      end

      def mark_unreceived_events_as_drafts(calendar_items)
        if calendar_items && calendar_items.any?
          received_external_ids = calendar_items.map(&:id)
          person.events
                .where(starts_at: GobiertoCalendars.sync_range)
                .where.not(external_id: nil)
                .where.not(external_id: received_external_ids)
                .update_all(state: GobiertoCalendars::Event.states[:pending])
        end
      end

      def log_preffix
        "[SYNC AGENDAS][MICROSOFT EXCHANGE]"
      end

      def log_missing_folder_error(folder_name)
        Rails.logger.info "#{log_preffix} Can't find #{folder_name} calendar folder for #{person.name} (id: #{person.id}). Wrong username, password or endpoint?"
      end

    end
  end
end
