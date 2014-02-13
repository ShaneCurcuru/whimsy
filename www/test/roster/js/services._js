#!/usr/bin/ruby

module Angular::AsfRosterServices
  class LDAP
    @@fetching = false

    @@index = {
      services: {},
      committers: {},
      pmcs: {},
      groups: {},
      members: []
    }

    def self.fetch_twice(url, &update)
      if_cached = {"Cache-Control" => "only-if-cached"}
      $http.get(url, cache: false, headers: if_cached).success { |result|
        update(result)
      }.finally {
        setTimeout 0 do
          $http.get(url, cache: false).success do |result, status|
            update(result) unless status == 304
          end
        end
      }
    end

    def self.get()
      unless @@fetching
        @@fetching = true
        self.fetch_twice 'json/ldap' do |result|
          angular.copy result.services, @@index.services
          angular.copy result.committers, @@index.committers
          angular.copy result.pmcs, @@index.pmcs
          angular.copy result.groups, @@index.groups
          angular.copy result.groups.member.memberUid, @@index.members
        end
      end

      return @@index
    end

    def self.committers
      return self.get().committers
    end

    def self.members
      return self.get().members
    end

    def self.services
      return self.get().services
    end

    def self.pmcs
      return self.get().pmcs
    end

    def self.groups
      return self.get().groups
    end
  end

  class INFO
    @@info = []

    def self.get(name)
      unless @@fetching
        @@fetching = true
        $http.get('json/info').success do |result|
          angular.copy result, @@info
        end
      end

      if name
        return @@info[name]
      else
        return @@info
      end
    end
  end
end
