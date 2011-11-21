module Paranoia
  def self.included(klazz)
    klazz.extend Query
  end

  module Query
    def paranoid? ; true ; end

    def only_deleted
      unscoped {
        where("#{Paranoia::DeleteColumn[self].to_s} is not null")
      }
    end
  end

  def destroy
    _run_destroy_callbacks { delete }
  end

  def delete
    self.update_attribute(Paranoia::DeleteColumn[self.class], Time.now) if !deleted? && persisted?
    freeze
  end
  
  def restore!
    update_attribute Paranoia::DeleteColumn[self.class], nil
  end

  def destroyed?
    !self.send(Paranoia::DeleteColumn[self.class]).nil?
  end
  alias :deleted? :destroyed?

  module DeleteColumn
    class << self
      def [](klass)
        delete_columns[klass] || :deleted_at
      end
      def []=(klass, column_name)
        delete_columns[klass] = column_name
      end
      def delete_columns
        @delete_columns ||= {}
      end
    end
  end
end

class ActiveRecord::Base
  def self.acts_as_paranoid(options={})
    alias_method :destroy!, :destroy
    alias_method :delete!,  :delete
    include Paranoia
    if column = options.delete(:with)
      Paranoia::DeleteColumn[self] = column
    end
    default_scope :conditions => { Paranoia::DeleteColumn[self] => nil }
  end

  def self.paranoid? ; false ; end
  def paranoid? ; self.class.paranoid? ; end
end
