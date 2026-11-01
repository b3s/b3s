# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "b3s:backfill_post_html", type: :task do
  subject(:task) { Rake::Task["b3s:backfill_post_html"] }

  let(:post) do
    travel_to(1.day.ago) { create(:post, body: "Hello", skip_preprocess: true) }
  end

  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    task.reenable
    post
    allow($stdout).to receive(:puts)
    task.invoke
    post.reload
  end

  it "renders the missing HTML" do
    expect(post.body_html).to include("Hello")
  end

  it "touches the post so cached fragments expire" do
    expect(post.updated_at).to be > 1.minute.ago
  end
end
