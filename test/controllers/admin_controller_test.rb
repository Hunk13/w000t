require 'test_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

# Admin controller tests
class AdminControllerTest < ActionController::TestCase
  setup do
    User.all.destroy
    W000t.all.destroy
    Sidekiq::Worker.clear_all

    request.env['HTTP_REFERER'] = 'previous_page'

    @user = FactoryGirl.create(:user)
    @admin_user = FactoryGirl.create(
      :user,
      pseudo: 'admin',
      email: 'email@admin.com',
      admin: true
    )
    @w000t = FactoryGirl.create(:w000t, long_url: 'http://google.com')
    @w000t_es = FactoryGirl.create(:w000t, long_url: 'http://google.es')
    @authentication_token = FactoryGirl.create(:authentication_token)
  end

  test 'should be redirected if not logged' do
    sign_in @user
    get :dashboard
    assert_redirected_to root_path
  end

  test 'should get dashboard as admin' do
    sign_in @admin_user
    get :dashboard
    assert_response :success
  end

  test 'should be redirected if not admin' do
    sign_in @user
    get :dashboard
    assert_redirected_to root_path
  end

  test 'should update all the w000ts' do
    sign_in @admin_user
    assert_difference 'UrlLifeChecker.jobs.size', W000t.all.count do
      post :check_all_w000ts
    end
    assert_redirected_to 'previous_page'
  end

  test 'should check one url' do
    sign_in @admin_user
    assert_difference 'UrlLifeChecker.jobs.size' do
      post :check_url, admin: { long_url: 'http://google.com' }
    end
    assert_redirected_to 'previous_page'
  end

  test 'should not create task to check url if none given' do
    sign_in @admin_user
    assert_raise ActionController::ParameterMissing do
      post :check_url
    end
    assert_difference 'UrlLifeChecker.jobs.size', 0 do
      post :check_url, admin: { url: 'fake argument' }
    end
  end

  test 'should reset sidekiq stats' do
    sign_in @admin_user
    allowed_params = %w( processed failed )
    allowed_params.each do |p|
      post :reset_sidekiq_stat, sidekiq: { reset_param: p }
      assert_redirected_to 'previous_page'
    end
  end

  test 'should not reset sidekiq stats with wrong params' do
    sign_in @admin_user
    wrong_params = %w( yo mama plop )
    wrong_params.each do |p|
      assert_raise ArgumentError do
        post :reset_sidekiq_stat, sidekiq: { reset_param: p }
      end
    end
  end
end
