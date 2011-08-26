require 'spec_helper'

describe Tinder::Room do
  before do
    @connection = Tinder::Connection.new('test', :token => 'mytoken')

    stub_connection(@connection) do |stub|
      stub.get('/room/80749.json') {[200, {}, fixture('rooms/show.json')]}
    end

    @room = Tinder::Room.new(@connection, 'id' => 80749)
  end

  describe "join" do
    before do
      stub_connection(@connection) do |stub|
        stub.post('/room/80749/join.json') {[200, {}, ""]}
      end
    end

    it "should post to join url" do
      @room.join
    end
  end

  describe "leave" do
    before do
      stub_connection(@connection) do |stub|
        stub.post('/room/80749/leave.json') {[200, {}, ""]}
      end
    end

    it "should post to leave url" do
      @room.leave
    end
  end

  describe "lock" do
    before do
      stub_connection(@connection) do |stub|
        stub.post('/room/80749/lock.json') {[200, {}, ""]}
      end
    end

    it "should post to lock url" do
      @room.lock
    end
  end

  describe "unlock" do
    before do
      stub_connection(@connection) do |stub|
        stub.post('/room/80749/unlock.json') {[200, {}, ""]}
      end
    end

    it "should post to unlock url" do
      @room.unlock
    end
  end

  describe "guest_url" do
    it "should use guest_invite_code if active" do
      @room.stub!(:guest_access_enabled? => true, :guest_invite_code => '123')
      @room.guest_url.should == "https://test.campfirenow.com/123"
    end

    it "should return nil when guest access is not enabled" do
      @room.stub!(:guest_access_enabled?).and_return(false)
      @room.guest_url.should be_nil
    end
  end

  it "should set guest_invite_code" do
    @room.guest_invite_code.should == "90cf7"
  end

  it "should set guest_access_enabled?" do
    @room.guest_access_enabled?.should be_true
  end

  describe "name=" do
    it "should put to update the room" do
      stub_connection(@connection) do |stub|
        stub.put('/room/80749.json') {[200, {}, ""]}
      end

      @room.name = "Foo"
    end
  end
end
