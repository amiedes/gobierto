require_dependency "gobierto_participation"

module GobiertoParticipation
  class Process < ApplicationRecord
    include User::Subscribable
    include GobiertoCommon::Searchable
    include GobiertoAttachments::Attachable
    include GobiertoCommon::ActsAsCollectionContainer

    algoliasearch_gobierto do
      attribute :site_id, :updated_at, :title_en, :title_es, :title_ca, :body_en, :body_es, :body_ca
      searchableAttributes ['title_en', 'title_es', 'title_ca', 'body_en', 'body_es', 'body_ca']
      attributesForFaceting [:site_id]
      add_attribute :resource_path, :class_name
    end

    translates :title, :body, :information_text

    belongs_to :site
    belongs_to :issue
    has_many :stages, -> { order(stage_type: :asc) }, dependent: :destroy, class_name: 'GobiertoParticipation::ProcessStage'

    enum visibility_level: { draft: 0, active: 1 }
    enum process_type: { process: 0, group_process: 1 }

    validates :site, :title, :body, presence: true
    validates :slug, uniqueness: { scope: :site }

    scope :sorted, -> { order(id: :desc) }

    accepts_nested_attributes_for :stages

    after_create :create_collections

    def to_s
      self.title
    end

    def pages_collection
      GobiertoCommon::Collection.find_by(container: self, item_type: 'GobiertoCms::Page')
    end

    def events_collection
      GobiertoCommon::Collection.find_by(container: self, item_type: 'GobiertoCalendars::Event')
    end

    def attachments_collection
      GobiertoCommon::Collection.find_by(container: self, item_type: 'GobiertoAttachments::Attachment')
    end

    private

    def create_collections
      # Events
      site.collections.create! container: self,  item_type: 'GobiertoCalendars::Event', slug: "calendar-#{self.slug}", title: self.title
      # Attachments
      site.collections.create! container: self,  item_type: 'GobiertoAttachments::Attachment', slug: "attachment-#{self.slug}", title: self.title
      # News / Pages
      site.collections.create! container: self,  item_type: 'GobiertoCms::Page', slug: "news-#{self.slug}", title: self.title
    end

  end
end
