# frozen_string_literal: true

class TriggerTestsController < ApplicationController
  # Test page for pg_sql_triggers features
  def index
    # Try to use engine's Registry, fall back to model
    @triggers = if defined?(PgSqlTriggers::Registry) && PgSqlTriggers::Registry.respond_to?(:all)
      PgSqlTriggers::Registry.all.order(:table_name, :trigger_name)
    else
      PgSqlTriggersRegistry.all.order(:table_name, :trigger_name)
    end
    @users = User.limit(10).order(created_at: :desc)
    @posts = Post.limit(10).order(created_at: :desc)
    @orders = Order.limit(10).order(created_at: :desc)
    @audit_logs = AuditLog.limit(20).order(occurred_at: :desc)
  end

  # Test user email validation trigger
  def test_user_email
    @user = User.new(user_params)
    
    if @user.save
      flash[:success] = "User created successfully! Email: #{@user.email}"
    else
      flash[:error] = "Validation failed: #{@user.errors.full_messages.join(', ')}"
    end
    
    redirect_to trigger_tests_path
  end

  # Test post slug generation trigger
  def test_post_slug
    @post = Post.new(post_params)
    
    if @post.save
      flash[:success] = "Post created! Title: #{@post.title}, Slug: #{@post.slug}"
    else
      flash[:error] = "Failed to create post: #{@post.errors.full_messages.join(', ')}"
    end
    
    redirect_to trigger_tests_path
  end

  # Test order total validation trigger
  def test_order_total
    @order = Order.new(order_params)
    
    begin
      if @order.save
        flash[:success] = "Order created! Total: $#{@order.total_amount}, Status: #{@order.status}"
      else
        flash[:error] = "Failed to create order: #{@order.errors.full_messages.join(', ')}"
      end
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = "Trigger validation error: #{e.message}"
    end
    
    redirect_to trigger_tests_path
  end

  # Test order status validation with condition
  def test_order_status
    @order = Order.new(order_params)
    
    begin
      if @order.save
        flash[:success] = "Order created! Status: #{@order.status}, Total: $#{@order.total_amount}"
      else
        flash[:error] = "Failed to create order: #{@order.errors.full_messages.join(', ')}"
      end
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = "Trigger validation error: #{e.message}"
    end
    
    redirect_to trigger_tests_path
  end

  # Test comment count update trigger
  def test_comment_count
    @comment = Comment.new(comment_params)
    
    if @comment.save
      @post = @comment.post.reload
      flash[:success] = "Comment added! Post '#{@post.title}' now has #{@post.comment_count} comment(s)"
    else
      flash[:error] = "Failed to create comment: #{@comment.errors.full_messages.join(', ')}"
    end
    
    redirect_to trigger_tests_path
  end

  # Test audit logging trigger (AFTER trigger)
  def test_audit_logging
    user = User.find_by(id: params[:user_id])
    
    if user.nil?
      flash[:error] = "User not found"
      redirect_to trigger_tests_path
      return
    end
    
    old_email = user.email
    user.email = params[:new_email] || "updated_#{Time.now.to_i}@example.com"
    
    if user.save
      audit_log = AuditLog.where(table_name: 'users', record_id: user.id.to_s)
                          .where(action: 'update')
                          .order(occurred_at: :desc)
                          .first
      
      if audit_log
        flash[:success] = "User updated! Email changed from '#{old_email}' to '#{user.email}'. Audit log created with ID: #{audit_log.id}"
      else
        flash[:warning] = "User updated but no audit log found (trigger may not be enabled)"
      end
    else
      flash[:error] = "Failed to update user: #{user.errors.full_messages.join(', ')}"
    end
    
    redirect_to trigger_tests_path
  end

  # Test trigger enable/disable
  def toggle_trigger
    # Try to use engine's Registry, fall back to model
    registry_class = if defined?(PgSqlTriggers::Registry) && PgSqlTriggers::Registry.respond_to?(:find_by)
      PgSqlTriggers::Registry
    else
      PgSqlTriggersRegistry
    end
    
    trigger = registry_class.find_by(trigger_name: params[:trigger_name])
    
    if trigger.nil?
      flash[:error] = "Trigger not found: #{params[:trigger_name]}"
      redirect_to trigger_tests_path
      return
    end
    
    begin
      if trigger.enabled?
        registry_class.disable_trigger(trigger.trigger_name)
        flash[:success] = "Trigger '#{trigger.trigger_name}' disabled"
      else
        registry_class.enable_trigger(trigger.trigger_name)
        flash[:success] = "Trigger '#{trigger.trigger_name}' enabled"
      end
    rescue => e
      flash[:error] = "Error toggling trigger: #{e.message}"
    end
    
    redirect_to trigger_tests_path
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end

  def post_params
    params.require(:post).permit(:user_id, :title, :body)
  end

  def order_params
    params.require(:order).permit(:user_id, :total_amount, :status)
  end

  def comment_params
    params.require(:comment).permit(:post_id, :user_id, :body)
  end
end

