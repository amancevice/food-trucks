Trucks        = new Meteor.Collection('trucks');
Days          = new Meteor.Collection('days');
Meals         = new Meteor.Collection('meals');
Neighborhoods = new Meteor.Collection('neighborhoods');
Locations     = new Meteor.Collection('locations');
Cities        = new Meteor.Collection('cities');

Meteor.subscribe('trucks');
Meteor.subscribe('days');
Meteor.subscribe('meals');
Meteor.subscribe('neighborhoods');
Meteor.subscribe('locations');
Meteor.subscribe('cities');

var date = new Date();
if(date.getDay() === 0)
  var day = 'Sunday';
else if(date.getDay() === 1)
  var day = 'Monday';
else if(date.getDay() === 2)
  var day = 'Tuesday';
else if(date.getDay() === 3)
  var day = 'Wednesday';
else if(date.getDay() === 4)
  var day = 'Thursday';
else if(date.getDay() === 5)
  var day = 'Friday';
else
  var day = 'Saturday';

if(date.getHours() >= 4 && date.getHours() < 10)
  var meal = 'Breakfast'
else if(date.getHours() >= 10 && date.getHours() < 15)
  var meal = 'Lunch';
else if(date.getHours() >= 15)
  var meal = 'Dinner';
else
  var meal = 'Late Night';

Session.set('selected_day',day);
Session.set('selected_meal',meal);

// FILTERS
// DAY
Template.dayfilter.filtered = function () {
  return (Session.get('selected_day') === null) ? '' : 'filtered';
};
Template.dayfilter.value = function () {
  return (Session.get('selected_day') === null) ? 'day...' : Session.get('selected_day').slice(0,3);
};
Template.dayfilter.events = {
  'click' : function () {
    Router.setMenu('days');
  }
};
Template.dayfilters.selected = function () {
  return Session.equals("selected_day", this.name) ? "selected" : '';
};
Template.dayfilters.values = function () {
  return Days.find({}, {sort: {pos: 1}});
};
Template.dayfilters.events = {
  'click' : function () {
    if(Session.equals("selected_day",this.name))
      Session.set("selected_day",null);
    else
      Session.set("selected_day",this.name);
    Router.setMenu('main');
  }
};

// MEAL
Template.mealfilter.filtered = function () {
  return (Session.get('selected_meal') === null) ? '' : 'filtered';
};
Template.mealfilter.value = function () {
  return (Session.get('selected_meal') === null) ? 'meal...' : Session.get('selected_meal');
};
Template.mealfilter.events = {
  'click' : function () {
    Router.setMenu('meals');
  }
};
Template.mealfilters.selected = function () {
  return Session.equals("selected_meal", this.name) ? "selected" : '';
};
Template.mealfilters.values = function () {
  return Meals.find({}, {sort: {pos: 1}});
};
Template.mealfilters.events = {
  'click' : function () {
    if(Session.equals("selected_meal",this.name))
      Session.set("selected_meal",null);
    else
      Session.set("selected_meal",this.name);
    Router.setMenu('main');
  }
};

// NEIGHBORHOOD
Template.neighborhoodfilter.filtered = function () {
  return (Session.get('selected_neighborhood') === null) ? '' : 'filtered';
};
Template.neighborhoodfilter.value = function () {
  return (Session.get('selected_neighborhood') === null) ? 'neighborhood...' : Session.get('selected_neighborhood');
};
Template.neighborhoodfilter.events = {
  'click' : function () {
    Router.setMenu('neighborhoods');
  }
};
Template.neighborhoodfilters.selected = function () {
  return Session.equals("selected_neighborhood", this.name) ? "selected" : '';
};
Template.neighborhoodfilters.values = function () {
  return Neighborhoods.find({city:'Boston'}, {sort: {name: 1}});
};
Template.neighborhoodfilters.events = {
  'click' : function () {
    if(Session.equals("selected_neighborhood",this.name)) {
      Session.set("selected_neighborhood",null);
      createCookie('bfthood',null,365);
    }
    else {
      Session.set("selected_neighborhood",this.name);
      createCookie('bfthood',this.name,365);
    }
    Router.setMenu('main');
  }
};

// TRUCKS
Template.trucks.trucks = function () {
  var c = 'Boston'
  var d = Session.get('selected_day');
  var m = Session.get('selected_meal');
  var n = Session.get('selected_neighborhood');
  var filter;
  if(d && m && n) {
    filter = {city: c, day: d, meal: m, neighborhood: n};
  }
  else if(d && m && !n) {
    filter = {city: c, day: d, meal: m};
  }
  else if(d && !m && n) {
    filter = {city: c, day: d, neighborhood: n};
  }
  else if(d && !m && !n) {
    filter = {city: c, day: d};
  }
  else if(!d && m && n) {
    filter = {city: c, meal: m, neighborhood: n};
  }
  else if(!d && m && !n) {
    filter = {city: c, meal: m};
  }
  else if(!d && !m && n) {
    filter = {city: c, neighborhood: n};
  }
  else {
    filter = {city: c};
  }
  var locations = Locations.find(filter);

  var trucks = new Array();
  locations.forEach( function (loc) {
    trucks.push(loc.name);
  });
  return Trucks.find({city: c, name: {$in: trucks}},{sort: {name: 1}});
};
Template.truck.selected = function () {
  return Session.equals("selected_truck", this.name) ? "selected" : '';
};
Template.truck.events = {
  'click': function () {
    if(Session.equals("selected_truck", this.name))
      Session.set("selected_truck", null);
    else
      Session.set("selected_truck", this.name);
  }
};

// DETAILS
Template.truck.squares = function () {
  var c = 'Boston'
  var d = Session.get('selected_day');
  var m = Session.get('selected_meal');
  var n = Session.get('selected_neighborhood');
  var t = Session.get('selected_truck');
  var filter;
  if(d && m && n) {
    filter = {city: c, name: t, day: d, meal: m, neighborhood: n};
  }
  else if(d && m && !n) {
    filter = {city: c, name: t, day: d, meal: m};
  }
  else if(d && !m && n) {
    filter = {city: c, name: t, day: d, neighborhood: n};
  }
  else if(d && !m && !n) {
    filter = {city: c, name: t, day: d};
  }
  else if(!d && m && n) {
    filter = {city: c, name: t, meal: m, neighborhood: n};
  }
  else if(!d && m && !n) {
    filter = {city: c, name: t, meal: m};
  }
  else if(!d && !m && n) {
    filter = {city: c, name: t, neighborhood: n};
  }
  else {
    filter = {city: c, name: t};
  }
  var locations = Locations.find(filter);
  var separator = ' - '
  var squares = new Array();
  locations.forEach( function (loc) {
    var breadcrumb = '';
    if(d === null)
      breadcrumb += loc.day;
    if(m === null && d === null)
      breadcrumb += separator;
    if(m === null)
      breadcrumb += loc.meal;
    if(n === null && (m === null || d === null))
      breadcrumb += separator;
    if(n === null)
      breadcrumb += loc.neighborhood;
    if(d === null || m === null || n === null)
      breadcrumb += separator;
    squares.push({breadcrumb: breadcrumb, square: loc.square, lat: loc.lat, lon: loc.lon});
  });
  return squares;
}

Template.truck.has_site = function () {
  return this.site != null && this.site != '';
}

Template.truck.short_site = function () {
  return this.site.replace("www.", "").split("/")[0];
}

Template.about.events = {
  'click': function () {
    Router.setMenu('aboutcontents');
  }
};

Template.aboutcontents.events = {
  'click': function () {
    Router.setMenu('main');
  }
};

var MenuRouter = Backbone.Router.extend({
  routes: {
    ":menu": "main"
  },
  main: function (menu) {
    Session.set("menu", menu);
    if(menu == 'main') {
      $('#days').hide();
      $('#meals').hide();
      $('#neighborhoods').hide();
      $('#aboutcontents').hide();
      $('#main').show();
    }
    else {
      $('#main').hide();
      $("#"+menu).show();
    }
  },
  setMenu: function (menu) {
    if(menu == 'main') {
      $('#days').hide();
      $('#meals').hide();
      $('#neighborhoods').hide();
      $('#aboutcontents').hide();
      $('#main').show();
    }
    else {
      $('#main').hide();
      $("#"+menu).show();
    }
    hideAddressBar();
    this.navigate(menu);
  }
});

Router = new MenuRouter;

Meteor.startup(function () {
  Backbone.history.start({pushState: true});
  Router.setMenu('main');
});

