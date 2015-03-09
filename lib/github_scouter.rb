# encoding: utf-8

require "github_scouter/version"
require 'octokit'

class Array
  def sum
    reduce(0) { |a,n| a + n }
  end
end

module GithubScouter
  class Scouter
    def self.atk_base(repo)
      return 0 if repo.private
      fork = repo.forks_count
      start = repo.stargazers_count

      if repo.fork
        (fork + start).to_f / 10
      else
        1 + (fork + 2) *  + start
      end
    end

    def self.language_rank(repos)
      repos
      .map(&:language)
      .delete_if(&:nil?)
      .reduce(Hash.new(0)) { |a,lang|
        a[lang] += 1
        a
      }.sort_by { |key,value|
        -value
      }
    end

    def initialize(name)
      @name = name
    end

    def client
      options = {
                 auto_paginate: true,
                 access_token: ENV['GITHUB_ACCESS_TOKEN'],
                }
      @client ||= Octokit::Client.new(options)
    end

    def repos
      @repos ||= client.repositories(@name)
    end

    def starred
      @starred ||= client.starred(@name)
    end

    def orgs
      @args ||= client.organizations(@name)
    end

    def atk
      repos.map { |repo| Scouter.atk_base(repo) }.sum
    end

    def int
      rank = Scouter.language_rank(repos)
      lang = rank.size
      sum = 0
      rank.each_with_index do |h,i|
        value = h[1]
        sum += value / (lang - i)
      end
      lang * sum
    end

    def agi
      orgs.map do |org_id|
        org = client.organization(org_id.login)
        repo = org.public_repos
        members = client.organization_members(org.login).count
        (repo.to_f + members)
      end.sum
    end
  end

  class Printer
    def initialize(scouter)
      @scouter = scouter
    end

    def put
      power
      puts ""
      repos_rank
      puts ""
      starred_rank
    end

    def power
      atk = @scouter.atk
      int = @scouter.int
      agi = @scouter.agi
      params = [atk,int,agi]
      puts "戦闘力: %d" % params.sum
      puts
      puts "攻撃力: %d 知力: %d すばやさ: %d" % params
    end

    def repos_rank
      rank(@scouter.repos, "repositories")
    end

    def starred_rank
      rank(@scouter.starred, "starred")
    end

    def rank(repos,label)
      rank = Scouter.language_rank(repos)
      puts "# #{label} (#{repos.count})"
      puts ""
      rank[0..9].each_with_index do |(key,value),i|
        puts "#{i+1}. ".ljust(4) + key.ljust(20) + value.to_s
      end
    end
  end
end
