Feature: Merge Articles
	
	As an admin
	In order to merge two articles having the same content
	I want to merge two articles
	
	Background:
		Given I am on the login page
		And the blog is set up
		And the following articles exist:
			| title     | author | body  | created_at         | published |
			| article 1 | admin  | body1 | 2012-11-22 5:24:11 | true      |
			| article 2 | admin  | body2 | 2012-11-22 5:25:00 | true      |
			
	Scenario: A non-admin cannot merge articles
		Given I am logged in with username "user" and password "useruser"
		When I follow "All Articles"
		Then I am on the Manage Articles page
		And I should see "article 1"
		When I go to the edit page for article 1
		Then I should not see "Merge Articles"
		
	Scenario: When articles are merged, the merged article should contain the text of both previous article
		Given I am logged into the admin panel
		And I am on the Manage Articles page
		Then I should see "article 1"
		And I should see "article 2"
		When I go to the edit page for article 1
		Then I should see "Merge Articles"
		When I fill in "merge_with" with the article id for article 2
		And I press "Merge"
		Then I should be on the admin content page
		And I should see "article 1"
		And I should not see "article 2"
		When I go to the show page for article 1
		Then I should see the body of the article "article 1"
		And I should see the body of the article "article 2"
		
	Scenario: When articles are merged, the merged article should have one author (either one of the authors of the two original articles)
		Given I am logged into the admin panel
		And I am on the Manage Articles page
		Then I should see "article 1"
		And I should see "article 2"
		When I go to the edit page for article 1
		Then I should see "Merge Articles"
		When I fill in "merge_with" with the article id for article 2
		And I press "Merge"
		Then I should be on the admin content page
		And I should see "article 1"
		And I should not see "article 2"
		Then the author of "article 1" should be the same as that of "article 2"
		
	Scenario: Comments on each of the two original articles need to all carry over and point to the new, merged article
		Given I am logged into the admin panel
		And I am on the Manage Articles page
		Then I should see "article 1"
		And I should see "article 2"
		When I go to the edit page for article 1
		Then I should see "Merge Articles"
		When I fill in "merge_with" with the article id for article 2
		And I press "Merge"
		Then I should be on the admin content page
		And I should see "article 1"
		And I should not see "article 2"
		Then the comments of "article 2" should be in "article 1"
	
	Scenario: The title of the new article should be the title from either one of the merged articles
		Given I am logged into the admin panel
		And I am on the Manage Articles page
		Then I should see "article 1"
		And I should see "article 2"
		When I go to the edit page for article 1
		Then I should see "Merge Articles"
		When I fill in "merge_with" with the article id for article 2
		And I press "Merge"
		Then I should be on the admin content page
		And I should see "article 1"
		And I should not see "article 2"
		Then the title of "article 1" should be the same as that of "article 2"
		
	Scenario: The form field containing the ID of the article to merge with must have the HTML attribute name set to merge_with
		Given I am logged into the admin panel
		And I am on the Manage Articles page
		Then I should see "article 1"
		And I should see "article 2"
		When I go to the edit page for article 1
		Then I should see "Merge Articles"
		And I should see the field "merge_with"
