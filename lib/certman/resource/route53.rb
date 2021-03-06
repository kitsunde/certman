module Certman
  module Resource
    # rubocop:disable Metrics/ModuleLength
    module Route53
      def create_txt_rset
        root_domain = PublicSuffix.domain(@domain)
        @hosted_zone = route53.list_hosted_zones.hosted_zones.find do |zone|
          PublicSuffix.domain(zone.name) == root_domain
        end
        route53.change_resource_record_sets(
          change_batch: {
            changes: [
              {
                action: 'CREATE',
                resource_record_set: {
                  name: "_amazonses.#{@domain}",
                  resource_records: [
                    {
                      value: '"' + @token + '"'
                    }
                  ],
                  ttl: 60,
                  type: 'TXT'
                }
              }
            ],
            comment: 'Generate by certman'
          },
          hosted_zone_id: @hosted_zone.id
        )
      end

      def create_mx_rset
        route53.change_resource_record_sets(
          change_batch: {
            changes: [
              {
                action: 'CREATE',
                resource_record_set: {
                  name: @domain,
                  resource_records: [
                    {
                      value: '10 inbound-smtp.us-east-1.amazonaws.com'
                    }
                  ],
                  ttl: 60,
                  type: 'MX'
                }
              }
            ],
            comment: 'Generate by certman'
          },
          hosted_zone_id: @hosted_zone.id
        )
      end

      def delete_txt_rset
        route53.change_resource_record_sets(
          change_batch: {
            changes: [
              {
                action: 'DELETE',
                resource_record_set: {
                  name: "_amazonses.#{@domain}",
                  resource_records: [
                    {
                      value: '"' + @token + '"'
                    }
                  ],
                  ttl: 60,
                  type: 'TXT'
                }
              }
            ],
            comment: 'Generate by certman'
          },
          hosted_zone_id: @hosted_zone.id
        )
      end

      def delete_mx_rset
        route53.change_resource_record_sets(
          change_batch: {
            changes: [
              {
                action: 'DELETE',
                resource_record_set: {
                  name: @domain,
                  resource_records: [
                    {
                      value: '10 inbound-smtp.us-east-1.amazonaws.com'
                    }
                  ],
                  ttl: 60,
                  type: 'MX'
                }
              }
            ],
            comment: 'Generate by certman'
          },
          hosted_zone_id: @hosted_zone.id
        )
      end

      def check_hosted_zone
        root_domain = PublicSuffix.domain(@domain)
        @hosted_zone_id = nil
        hosted_zone = route53.list_hosted_zones.hosted_zones.find do |zone|
          if PublicSuffix.domain(zone.name) == root_domain
            @hosted_zone_id = zone.id
            next true
          end
        end
        raise "Hosted Zone #{root_domain} does not exist" unless hosted_zone
      end

      def check_txt_rset
        res = route53.list_resource_record_sets(
          hosted_zone_id: @hosted_zone_id,
          start_record_name: "_amazonses.#{@domain}.",
          start_record_type: 'TXT'
        )
        raise "_amazonses.#{@domain} TXT already exist" unless res.resource_record_sets.empty?
      end

      def check_mx_rset
        res = route53.list_resource_record_sets(
          hosted_zone_id: @hosted_zone_id,
          start_record_name: "#{@domain}.",
          start_record_type: 'MX'
        )
        raise "#{@domain} MX already exist" unless res.resource_record_sets.empty?
      end

      def route53
        @route53 ||= Aws::Route53::Client.new
      end
    end
  end
end
