module Certman
  class CLI < Thor
    desc 'request [DOMAIN]', 'Request ACM Certificate with only AWS managed services'
    option :remain_resources, type: :boolean
    def request(domain)
      pastel = Pastel.new
      prompt = TTY::Prompt.new
      return unless prompt.yes?(pastel.red('NOTICE! Certman support *us-east-1* only, now. OK?'))
      return unless prompt.yes?(pastel.red('NOTICE! When requesting, Certman replace Active Receipt Rule Set. OK?'))
      client = Certman::Client.new(domain)
      Signal.trap(:INT) do
        puts ''
        puts pastel.red('Rollback start.')
        client.rollback
      end
      cert_arn = client.request(options[:remain_resources])
      puts 'Done.'
      puts ''
      puts "certificate_arn: #{pastel.cyan(cert_arn)}"
      puts ''
    end

    desc 'delete [DOMAIN]', 'Delete ACM Certificate'
    def delete(domain)
      Certman::Client.new(domain).delete
      puts 'Done.'
      puts ''
    end
  end
end
