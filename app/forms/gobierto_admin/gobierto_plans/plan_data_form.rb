# frozen_string_literal: true

module GobiertoAdmin
  module GobiertoPlans
    class PlanDataForm < BaseForm
      class CSVRowInvalid < ArgumentError; end
      class StatusMissing < ArgumentError; end
      class ExternalIdTaken < ArgumentError; end

      REQUIRED_COLUMNS = %w(Node.Title).freeze

      attr_accessor(
        :plan,
        :csv_file
      )

      validates :plan, :csv_file, presence: true
      validate :csv_file_format

      def save
        save_plan_data if valid?
      end

      private

      def plan_class
        ::GobiertoPlans::Plan
      end

      def node_class
        ::GobiertoPlans::Node
      end

      def category_class
        ::GobiertoPlans::Category
      end

      def categories_table
        category_class.table_name
      end

      def save_plan_data
        if csv_file.present?
          ActiveRecord::Base.transaction do
            import_nodes
          end
        end
      rescue CSVRowInvalid => e
        errors.add(:base, :invalid_row, row_data: e.message)
        false
      rescue StatusMissing, ExternalIdTaken => e
        errors.add(:base, e.class.name.demodulize.underscore.to_sym, row_data: e.message)
        false
      rescue ActiveRecord::RecordNotDestroyed
        errors.add(:base, :used_resource)
        false
      end

      def csv_file_format
        errors.add(:base, :file_not_found) unless csv_file.present?
        errors.add(:base, :invalid_format) unless csv_file_content
        unless !csv_file_content || (REQUIRED_COLUMNS - csv_file_content.headers).blank? && csv_file_content.headers.any? { |header| /Level \d+/.match?(header) }
          errors.add(:base, :invalid_columns)
        end
      end

      def import_nodes
        position_counter = 0
        csv_file_content.each do |row|
          row_decorator = ::GobiertoPlans::RowNodeDecorator.new(row, plan: @plan)
          row_decorator.categories.each do |category|
            next unless category.new_record?

            category.position = position_counter
            raise CSVRowInvalid, row_decorator.to_csv unless category.name.present? && category.save

            position_counter += 1
          end
          next unless (node = row_decorator.node).present?

          raise ExternalIdTaken, row_decorator.to_csv if row_decorator.external_id_taken?
          raise CSVRowInvalid, row_decorator.to_csv unless REQUIRED_COLUMNS.all? { |column| row_decorator[column].present? } && node.save
          raise StatusMissing, row_decorator.to_csv if row_decorator.status_missing

          custom_fields_form = ::GobiertoCommon::CustomFieldRecordsForm.new(
            site_id: @plan.site.id,
            item: node,
            instance: @plan,
            with_version: true
          )

          custom_fields_form.custom_field_records = row_decorator.custom_field_records_values
          custom_fields_form.save
        end
      end

      def col_sep
        separators = [",", ";"]
        first_line = csv_file.open.first
        separators.max do |a, b|
          first_line.split(a).count <=> first_line.split(b).count
        end
      end

      def csv_file_content
        @csv_file_content ||= begin
                                ::CSV.read(csv_file.open, headers: true, col_sep: col_sep)
                              rescue ArgumentError, CSV::MalformedCSVError
                                false
                              end
      end
    end
  end
end
