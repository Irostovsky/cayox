module Admin
  class Notifications < Application
    is_admin_controller

    def index
      @filter_form = NotificationsFilterForm.new(params[:notifications_filter_form])
      conditions = {}
      conditions[:user_id] = @filter_form.user_id unless @filter_form.user_id.blank?
      conditions[:type] = @filter_form.type_ unless @filter_form.type_.blank?
      if @filter_form.valid?
        conditions[:created_at.gte] = @filter_form.date_from if @filter_form.date_from
        conditions[:created_at.lt] = @filter_form.date_to + 1 if @filter_form.date_to
      end
      p conditions
      @page_count, @notifications = Notification.paginated(conditions.merge!(:per_page => 20, :page => pagination_page, :order => [:created_at.desc]))
      @users = User.all(:order => [:name])
      @notification_types = Notification.types.to_a.sort_by { |t| t[1] }
      render
    end

    def resend(notification_ids=[])
      notifications = Notification.all(:id => notification_ids)
      groupped_notifications = notifications.group_by { |n| n.user }
      groupped_notifications.each do |user, notifications|
        if notifications.size == 1
          notifications.first.send!
        else
          SummaryNotification.send!(user, notifications)
        end
      end
      filters = URI.parse(request.env['HTTP_REFERER']).query.to_s
      redirect resource(:admin, :notifications) << "?" << filters, :message => { :notice => _("Selected notifications have been resent.") }
    end

  end
end