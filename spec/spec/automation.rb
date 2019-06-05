require 'spec_helper'


   describe 'searchstudio' do

     it 'Searching for a studio and the schedules on the WW website', js: true do

      # Navigate to https://www.weightwatchers.com/us/
      visit("https://www.weightwatchers.com/us/")

      # Verify loaded page title matches “WW (Weight Watchers): Weight Loss & Wellness Help”
      expect(page).to have_title "WW (Weight Watchers): Weight Loss & Wellness Help"

      # On the right corner of the page, click on “Find a Studio”
      find('#ela-menu-visitor-desktop-supplementa_find-a-studio').click

      # Verify loaded page title contains “Find a Studio”
      expect(page).to have_content "Find a Studio"

      # In the search field, search for meetings for zip code: 10011
      fill_in "meetingSearch", with: '10011'

      within '.meeting-finder__header-search' do
        click_button ('Submit')
      end

      # Print the title of the first result and the distance (located on the right of location title/name)
      expect(page).to have_content "WW Studio Flatiron"
      puts page.first('.location__top', visible: false).text

      #expect(page).to have_content "0.49 mi."
      #puts page.first('.location__distance', visible: false).text


      # Click on the first search result
      first(".meeting-location").click

      # verify displayed location name/title matches with the name of the first searched result that was clicked.
      expect(page).to have_content "WW Studio Flatiron"
      expect(page).to have_content "14 W 23RD ST 2ND FL"
      expect(page).to have_content "NEW YORK, NY 10010"

      # From this location page, print TODAY’s hours of operation (located towards the bottom of the page
      time = Time.now    # Convert number of seconds into Time object.
      date = time.wday
      puts all('.hours-list-item')[date].text




  end
end
