# frozen_string_literal: true

require_relative '../../test_helper'

class TechRadar::TechnologiesControllerTest < Redmine::ControllerTest
  tests TechRadar::TechnologiesController

  fixtures :users, :roles

  def setup
    User.current = nil
    @admin = User.find_by(login: 'admin')
    @jsmith = User.find_by(login: 'jsmith')
    @request.session[:user_id] = @admin.id
    @ruby = TechRadar::Technology.create!(name: 'Ruby')
    @rails = TechRadar::Technology.create!(name: 'Rails')
  end

  def test_index_lists_technologies_by_name
    get :index

    assert_response :success
    names = css_select('table.tech-radar-technologies td.name').map { |td| td.text.strip }

    assert_equal %w[Rails Ruby], names
  end

  def test_index_shows_rating_count_per_technology
    TechRadar::Rating.create!(user: @admin, technology: @ruby,
                              can_level: :advanced, want_level: :yes)
    TechRadar::Rating.create!(user: @jsmith, technology: @ruby,
                              can_level: :beginner, want_level: :no)

    get :index

    assert_select 'tr:has(td.name a[href=?]) td.ratings', edit_tech_radar_technology_path(@ruby), text: '2'
    assert_select 'tr:has(td.name a[href=?]) td.ratings', edit_tech_radar_technology_path(@rails), text: '0'
  end

  def test_index_warns_about_ratings_in_delete_confirmation
    TechRadar::Rating.create!(user: @admin, technology: @ruby,
                              can_level: :advanced, want_level: :yes)

    get :index

    assert_select 'a.icon-del[href=?][data-confirm=?]', tech_radar_technology_path(@ruby),
                  'Delete this technology and its rating?'
    assert_select 'a.icon-del[href=?][data-confirm=?]', tech_radar_technology_path(@rails),
                  'Delete this technology?'
  end

  def test_index_shows_no_data_without_technologies
    TechRadar::Technology.delete_all

    get :index

    assert_select 'p.nodata'
    assert_select 'table.tech-radar-technologies', count: 0
  end

  def test_index_marks_technologies_tab_selected
    get :index

    assert_select '.tabs a.selected[href=?]', tech_radar_technologies_path
  end

  def test_new_renders_form
    get :new

    assert_response :success
    assert_select 'form[action=?] input[name=?]', tech_radar_technologies_path, 'tech_radar_technology[name]'
  end

  def test_create_adds_technology_and_redirects_to_index
    assert_difference 'TechRadar::Technology.count', 1 do
      post :create, params: { tech_radar_technology: { name: 'Elixir' } }
    end

    assert_redirected_to tech_radar_technologies_path
    assert TechRadar::Technology.exists?(name: 'Elixir')
  end

  def test_create_with_duplicate_name_rerenders_form
    assert_no_difference 'TechRadar::Technology.count' do
      post :create, params: { tech_radar_technology: { name: 'Ruby' } }
    end

    assert_response :unprocessable_entity
    assert_select '#errorExplanation'
  end

  def test_edit_renders_form_with_current_name
    get :edit, params: { id: @ruby.id }

    assert_response :success
    assert_select 'input[name=?][value=?]', 'tech_radar_technology[name]', 'Ruby'
  end

  def test_edit_returns_not_found_for_unknown_technology
    get :edit, params: { id: 0 }

    assert_response :not_found
  end

  def test_update_renames_technology_and_redirects_to_index
    patch :update, params: { id: @ruby.id, tech_radar_technology: { name: 'Ruby 3' } }

    assert_redirected_to tech_radar_technologies_path
    assert_equal 'Ruby 3', @ruby.reload.name
  end

  def test_update_with_blank_name_rerenders_form
    patch :update, params: { id: @ruby.id, tech_radar_technology: { name: '' } }

    assert_response :unprocessable_entity
    assert_select '#errorExplanation'
    assert_equal 'Ruby', @ruby.reload.name
  end

  def test_destroy_removes_technology_and_its_ratings
    TechRadar::Rating.create!(user: @admin, technology: @ruby,
                              can_level: :advanced, want_level: :yes)

    assert_difference ['TechRadar::Technology.count', 'TechRadar::Rating.count'], -1 do
      delete :destroy, params: { id: @ruby.id }
    end

    assert_redirected_to tech_radar_technologies_path
  end

  def test_destroy_returns_not_found_for_unknown_technology
    delete :destroy, params: { id: 0 }

    assert_response :not_found
  end

  def test_index_allowed_for_non_admin_with_manage_permission
    Role.non_member.add_permission!(:manage_technologies)
    @request.session[:user_id] = @jsmith.id

    get :index

    assert_response :success
  end

  def test_index_forbidden_for_user_without_manage_permission
    @request.session[:user_id] = @jsmith.id

    get :index

    assert_response :forbidden
  end

  def test_create_forbidden_for_user_without_manage_permission
    @request.session[:user_id] = @jsmith.id

    assert_no_difference 'TechRadar::Technology.count' do
      post :create, params: { tech_radar_technology: { name: 'Elixir' } }
    end

    assert_response :forbidden
  end

  def test_destroy_forbidden_for_user_without_manage_permission
    @request.session[:user_id] = @jsmith.id

    assert_no_difference 'TechRadar::Technology.count' do
      delete :destroy, params: { id: @ruby.id }
    end

    assert_response :forbidden
  end

  def test_index_redirects_anonymous_user_to_login
    @request.session[:user_id] = nil

    get :index

    assert_redirected_to %r{/login}
  end
end
