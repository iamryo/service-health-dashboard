class Service < ActiveRecord::Base
	#belongs_to :dependent
  has_many :events
	attr_accessible :description, :name, :order, :slug, :version, :invisible, :service_id#, :dependent

  extend FriendlyId
  friendly_id :name, use: :slugged
  
  def self.platform_maintenance(nf_version)
    Event.includes(:service).
          where(:events=> {:invisible=>false}).
          where(start: (DateTime.now-12.hours)..DateTime.now+90.days).
          where(status_id: 2).
          where(:services => {:version=> nf_version}).
          order('start')
  end


  def self.maintenance(service)
    Event.where(:events=> {:invisible=>false}).
          where(start: (DateTime.now)..DateTime.now+90.days).
          where(status_id: 2).
          where(:service_id => service).
          order('start')
  end

	def current_status
		e = Event.where('service_id = ?', self.id.to_s).
              where('start < ? ', DateTime.now).
              where('invisible = ?', false).
              order('start').last
    if e == nil
      e = most_recent_event(DateTime.now)
    end

    e

	end

  def most_recent_event(date)
    e = Event.where('service_id = ?', self.id.to_s).
              where('invisible = ?', false).
              where('start <= ?', date).
              order('start').last
    e == nil ? nil : e
  end

	def most_severe_event_for_date(date)
    events = Event.where('service_id = ?',self.id.to_s).
                  where('invisible = ?', false). 
                  where(start: date.beginning_of_day()..date.end_of_day()).
                  order('status_id DESC').
                  first

    if events == nil
      events = self.most_recent_event(date)
    end

    events

	end

  def x_days_statuses(days_to_go_back)
    events = []
    day = DateTime.now - days_to_go_back.days
    days = (day .. day + days_to_go_back).to_a { |date|  '#{date}' }

    #adds a second 'today' for displaying the current status vs the daily severity status
    days << days.last
    days.reverse!

    for day in days
      events << most_severe_event_for_date(day)
    end
    events
  end

end
