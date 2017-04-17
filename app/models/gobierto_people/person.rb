require_dependency "gobierto_people"

module GobiertoPeople
  class Person < ApplicationRecord
    include GobiertoCommon::DynamicContent
    include User::Subscribable
    include GobiertoCommon::Sortable
    include GobiertoCommon::Searchable

    translates :charge, :bio
    include GobiertoCommon::LocalizedContent

    algoliasearch_gobierto do
      attribute :site_id, :name, :charge_en, :charge_es, :charge_ca, :bio_en, :bio_es, :bio_ca, :updated_at
      searchableAttributes ['name', 'charge_en', 'charge_es', 'charge_ca', 'bio_en', 'bio_es', 'bio_ca']
      attributesForFaceting [:site_id]
      add_attribute :resource_path, :class_name
    end

    belongs_to :admin, class_name: "GobiertoAdmin::Admin"
    belongs_to :site
    belongs_to :political_group

    has_many :events, class_name: "PersonEvent", dependent: :destroy
    has_many :statements, class_name: "PersonStatement", dependent: :destroy
    has_many :posts, class_name: "PersonPost", dependent: :destroy

    scope :sorted, -> { order(position: :asc, created_at: :desc) }
    scope :by_site, ->(site) { where(site_id: site.id) }

    enum visibility_level: { draft: 0, active: 1 }
    enum category: { politician: 0, executive: 1 }
    enum party: { government: 0, opposition: 1 }

    validates :email, format: { with: User::EMAIL_ADDRESS_REGEXP }, allow_blank: true

    def self.csv_columns
      [:id, :name, :email, :charge, :bio, :bio_url, :avatar_url, :category, :political_group, :party, :created_at, :updated_at]
    end

    def as_csv
      political_group_name = political_group.try(:name)

      [id, name, email, charge, bio, bio_url, avatar_url, category, political_group_name, party, created_at, updated_at]
    end
  end
end
