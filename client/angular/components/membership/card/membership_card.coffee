Records        = require 'shared/services/records.coffee'
AbilityService = require 'shared/services/ability_service.coffee'
ModalService   = require 'shared/services/modal_service.coffee'
RecordLoader   = require 'shared/services/record_loader.coffee'
I18n           = require 'shared/services/i18n.coffee'
Records        = require 'shared/services/records.coffee'

angular.module('loomioApp').directive 'membershipCard', ->
  scope: {group: '=', pending: "=?"}
  restrict: 'E'
  templateUrl: 'generated/components/membership/card/membership_card.html'
  replace: false
  controller: ['$scope', ($scope) ->
    $scope.vars = {}
    $scope.show = ->
      return false if $scope.recordCount() == 0
      $scope.initialFetch() if $scope.canView()
      $scope.canView()

    $scope.plusUser = Records.users.build(avatarKind: 'mdi-plus')

    $scope.canView = ->
      if $scope.pending
        AbilityService.canViewPendingMemberships($scope.group)
      else
        AbilityService.canViewMemberships($scope.group)

    if $scope.pending
      $scope.cardTitle = 'membership_card.invitations'
      $scope.order = '-createdAt'
    else
      $scope.cardTitle = "membership_card.#{$scope.group.targetModel().constructor.singular}_members"
      $scope.pollType = I18n.t("poll_types.#{$scope.group.targetModel().pollType}")
      $scope.order = '-admin'

    $scope.recordCount = ->
      if $scope.pending
        $scope.group.pendingMembershipsCount
      else
        $scope.group.membershipsCount - $scope.group.pendingMembershipsCount

    $scope.toggleSearch = ->
      $scope.vars.fragment = ''
      $scope.searchOpen = !$scope.searchOpen
      setTimeout -> document.querySelector('.membership-card__search input').focus()

    $scope.showLoadMore = ->
      !$scope.loader.exhausted    &&
      !$scope.vars.fragment       &&
      !$scope.loader.loading

    $scope.canAddMembers = ->
      AbilityService.canAddMembers($scope.group)

    $scope.memberships = ->
      if $scope.vars.fragment
        _.filter $scope.records(), (membership) =>
          _.contains membership.userName().toLowerCase(), $scope.vars.fragment.toLowerCase()
      else
        $scope.records()

    $scope.initialFetch = ->
      $scope.loader.fetchRecords(per: 4) unless $scope.fetched
      $scope.fetched = true

    $scope.records = ->
      if $scope.pending
        $scope.group.pendingMemberships()
      else
        $scope.group.activeMemberships()

    $scope.invite = ->
      ModalService.open 'AnnouncementModal', announcement: ->
        Records.announcements.buildFromModel($scope.group.targetModel())

    $scope.fetchMemberships = ->
      return unless $scope.vars.fragment
      Records.memberships.fetchByNameFragment($scope.vars.fragment, $scope.group.key)

    $scope.loader = new RecordLoader
      collection: 'memberships'
      params:
        per: 20
        pending: $scope.pending
        group_id: $scope.group.id

  ]
