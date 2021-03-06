# encoding : utf-8
require 'test_helper'

class RedirectorTest < ActiveSupport::TestCase

  test "truth" do
    assert_kind_of Module, Redirector
  end

  test "merge with tracking_url if it exists" do
    Redirector.setup do |config|
      config.tracking_url = "http://track.example.com/?url={url}"
    end
    p = Product.new
    assert_equal 'http://track.example.com/?url=http://network.com?url=http%3A%2F%2Fstore.com%2Fproduct&epi=product_foobar', p.redirect_path
  end

  test "ensure that Mongoid::Document responds to redirect_with" do
    assert Product.respond_to? :redirect_with
  end

  test "generate redirect_path for model" do
    p = Product.new
    assert_equal 'http://network.com?url=http%3A%2F%2Fstore.com%2Fproduct&epi=product_foobar', p.redirect_path
  end

  test "support :landing_page option for redirect_path" do
    p = Product.new
    url = p.redirect_path(landing_page: 'http://example.com/custom')
    assert_equal 'http://network.com?url=http%3A%2F%2Fexample.com%2Fcustom&epi=product_foobar', url
  end

  test "ignore encoding hosts" do
    ignored_hosts = [
      'click.affiliator.com',
      'track.adtraction.com',
      '*.partner-ads.com',
      '*.smartresponse-media.com',
      'ads.guava-affiliate.com'
    ]
    assert_equal ignored_hosts, Redirector.ignore_encoding_hosts
  end

  test 'skip url escape if affiliate_url matches ignore filter' do
    p = Product.new affiliate_uri: 'http://click.affiliator.com?url={url}&epi={epi}'
    assert_equal 'http://click.affiliator.com?url=http://store.com/product&epi=product_foobar', p.redirect_path
  end

  test 'should use (unescaped) path_url if build_url is blank' do
    p = Product.new affiliate_uri: nil
    assert_equal "http://store.com/product", p.redirect_path
  end

  test 'should return nil when no path exists' do
    p = Product.new url: nil
    assert_nil p.redirect_path
  end

  test "should support String as option" do
    p = Product.new
    p.class_eval { redirect_with :base => proc { |x| x.affiliate_uri }, :path => :url, :epi => '{invk_epi}' }
    assert_equal 'http://network.com?url=http%3A%2F%2Fstore.com%2Fproduct&epi={invk_epi}', p.redirect_path
  end

  test "without epi option" do
  end

  test "custom finder method as option" do
    klass = Class.new Product
    klass.class_eval do
      redirect_with :base => 'hello', :path => 'world', :epi => 'foo', :find_method => :my_custom_find
      def self.my_custom_find(resource_id); end
    end
    klass.expects(:my_custom_find).once
    klass.find_for_redirect(123)
  end

end

class RedirectRoutingTest < ActionController::TestCase

  test 'redirect_for' do
    assert_recognizes({ controller: 'redirector/redirect', product_id: "123", action: 'redirect' }, { path: 'products/123/redirect', method: :get })
    assert_named_route "/products/123/redirect", :redirect_product_path, 123
  end

  protected

    def assert_named_route(result, *args)
      assert_equal result, @routes.url_helpers.send(*args)
    end

end

class Redirector::RedirectControllerTest < ActionController::TestCase

  test 'redirect action and view' do
    product = Product.new
    get :redirect, product_id: product.id
    assert_response :success
    assert_template "redirect"
    assert_select "script", 'document.location.href = "http://network.com?url=http%3A%2F%2Fstore.com%2Fproduct&epi=product_foobar";'
  end

end

class Redirector::ViewHelpersTest < ActionView::TestCase

  def setup
    @product = Product.new(name: 'foobar')
  end

  test 'Included in ActionView::Base' do
    assert ActionView::Base.instance_methods.include? :redirect_link_to
  end

  test 'redirect_link_to with resource' do
    expected = %q{<a data-external="true" rel="nofollow" href="/products/foobar/redirect">Go to product</a>}
    assert_equal(expected, redirect_link_to('Go to product', @product))
  end

  test "redirect_link_to with block" do
    expected = %q{<a data-external="true" rel="nofollow" href="/products/foobar/redirect">My block data</a>}
    assert_equal(expected, redirect_link_to(@product) { 'My block data' })
  end

  test 'redirect_link_to with resource and additional html_options' do
    expected = %q{<a data-external="true" rel="nofollow" class="qwerty" href="/products/foobar/redirect">Go to product</a>}
    assert_equal(expected, redirect_link_to('Go to product', @product, class: 'qwerty'))
  end

  test 'redirect_link_to with block and additional html_options' do
    expected = %q{<a data-external="true" rel="nofollow" class="qwerty" href="/products/foobar/redirect">My block data</a>}
    assert_equal(expected, redirect_link_to(@product, class: 'qwerty') { 'My block data'} )
  end

  test 'redirect_link_to with overwritten html_options' do
    expected = %q{<a data-external="false" rel="foobar" class="qwerty" href="/products/foobar/redirect">My block data</a>}
    assert_equal(expected, redirect_link_to(@product, class: 'qwerty', 'data-external' => false, 'rel' => 'foobar' ) { 'My block data'} )
  end

end
