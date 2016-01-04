Trucks        = new Meteor.Collection('trucks');
Days          = new Meteor.Collection('days');
Meals         = new Meteor.Collection('meals');
Neighborhoods = new Meteor.Collection('neighborhoods');
Locations     = new Meteor.Collection('locations');
Cities        = new Meteor.Collection('cities');

Meteor.publish('cities',        function() {return Cities.find();})
Meteor.publish('trucks',        function() {return Trucks.find();});
Meteor.publish('days',          function() {return Days.find();});
Meteor.publish('meals',         function() {return Meals.find();});
Meteor.publish('neighborhoods', function() {return Neighborhoods.find();});
Meteor.publish('locations',     function() {return Locations.find();});
