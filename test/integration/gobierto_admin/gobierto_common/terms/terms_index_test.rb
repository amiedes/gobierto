# frozen_string_literal: true

require "test_helper"

module GobiertoCommon
  module GobiertoAdmin
    class TermsIndexTest < ActionDispatch::IntegrationTest

      def setup
        super
        @path = admin_common_vocabulary_terms_path(vocabulary)
      end

      def vocabulary
        gobierto_common_vocabularies(:animals)
      end

      def admin
        @admin ||= gobierto_admin_admins(:nick)
      end

      def site
        @site ||= sites(:madrid)
      end

      def terms
        @terms ||= vocabulary.terms
      end

      def first_term
        @first_term ||= terms.sorted.first
      end

      def test_terms_index
        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit @path

            within "table tbody" do
              assert has_selector?("tr", count: terms.size)

              terms.each do |term|
                assert has_selector?("tr#term-item-#{term.id}")

                within "tr#term-item-#{term.id}" do
                  assert has_link?(term.name.to_s)
                end
              end
            end
          end
        end
      end

      def test_terms_order
        terms.update_all(term_id: nil, level: 0)

        with_signed_in_admin(admin) do
          with_current_site(site) do
            visit @path
            ordered_names = page.all(:xpath, '(.//tr//td[3])').map(&:text)
            assert_equal terms.sorted.map(&:name), ordered_names

            first_term.update_attribute(:position, 1000)

            visit @path
            ordered_names = page.all(:xpath, '(.//tr//td[3])').map(&:text)
            assert_equal first_term.name, ordered_names.last
          end
        end
      end
    end
  end
end
