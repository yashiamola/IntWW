require 'spec_helper'


scenario 'Searching for a studio and the schedules on the WW website', js: true do

#Navigate to https://www.weightwatchers.com/us/
 visit "https://www.weightwatchers.com/us/"
 wait_for_ajax


 # Verify loaded page title matches “WW (Weight Watchers): Weight Loss & Wellness Help”
 expect(page).to have_content "WW (Weight Watchers): Weight Loss & Wellness Help"

 # On the right corner of the page, click on “Find a Studio”
 find('#ela-menu-visitor-desktop-supplementa_find-a-studio').click
 # @yasser :  Do I need this, wait_for_ajax as it navigates to a new page ?  or should I use Clini_link ?

 # Verify loaded page title contains “Find WW Studios & Meetings Near You | WW USA”
 expect(page).to have_content "Find WW Studios & Meetings Near You | WW USA"

 # In the search field, search for meetings for zip code: 10011
 find('#meetingSearch').set("10011")

 #Print the title of the first result and the distance (located on the right of location title/name) #TODO
puts page.first('.location__name').text
puts page.first('.location__distance').text



 # Click on the first search result
 Click_on "#ml-1180510"

 # verify displayed location name/title matches with the name of the first searched result that was clicked.
 expect(page).to have_content "WW Studio Flatiron"
 expect(page).to have_content "14 W 23RD ST 2ND FL"
 expect(page).to have_content "NEW YORK, NY 10010"

 # From this location page, print TODAY’s hours of operation (located towards the bottom of the page #TODO
puts page.find('.{'hours-list--currentday': (day.id == today) }').text
 


 # Create a method to print the number of meeting the each person(under the scheduled time) has a particular day of the week

 #def printMeetings("Sun")
 #end


end
