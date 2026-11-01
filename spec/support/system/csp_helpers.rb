# frozen_string_literal: true

module CspHelpers
  VIOLATION_RECORDER = <<~JS
    window.cspViolations = [];
    document.addEventListener("securitypolicyviolation", (event) => {
      window.cspViolations.push({
        directive: event.effectiveDirective,
        blockedURI: event.blockedURI,
        sourceFile: event.sourceFile,
        lineNumber: event.lineNumber,
        sample: event.sample
      });
    });
  JS

  def record_csp_violations
    @csp_recorder = page.driver.browser.execute_cdp(
      "Page.addScriptToEvaluateOnNewDocument", source: VIOLATION_RECORDER
    )
  end

  def stop_recording_csp_violations
    return unless @csp_recorder

    page.driver.browser.execute_cdp(
      "Page.removeScriptToEvaluateOnNewDocument",
      identifier: @csp_recorder["identifier"]
    )
    @csp_recorder = nil
  end

  def csp_violations
    page.evaluate_script("window.cspViolations")
  end
end

RSpec.configure do |config|
  config.include CspHelpers, type: :system
  config.after(:each, type: :system) { stop_recording_csp_violations }
end
