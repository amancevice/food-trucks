class Init < ActiveRecord::Migration
  def change
    create_table :providers do |t|
      t.belongs_to :city
      t.string     :name
      t.string     :endpoint
      t.string     :type
    end

    create_table :cities do |t|
      t.string :name
      t.string :key
      t.string :timezone
    end

    create_table :neighborhoods do |t|
      t.belongs_to :city
      t.string     :name
    end

    create_table :places do |t|
      t.belongs_to :city
      t.belongs_to :neighborhood
      t.belongs_to :provider
      t.string     :name
      t.float      :latitude
      t.float      :longitude
      t.string     :type
    end

    create_table :trucks do |t|
      t.belongs_to :city
      t.string     :name
      t.string     :site
    end

    create_table :gigs do |t|
      t.belongs_to :city
      t.belongs_to :place
      t.belongs_to :truck
      t.belongs_to :provider
      t.string     :uuid
      t.datetime   :start
      t.datetime   :stop
    end
  end
end
