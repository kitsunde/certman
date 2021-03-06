module Certman
  module Resource
    module ACM
      def request_certificate
        res = acm.request_certificate(
          domain_name: @domain,
          subject_alternative_names: [@domain],
          domain_validation_options: [
            {
              domain_name: @domain,
              validation_domain: @domain
            }
          ]
        )
        @cert_arn = res.certificate_arn
      end

      def delete_certificate
        current_cert = acm.list_certificates.certificate_summary_list.find do |cert|
          cert.domain_name == @domain
        end
        raise 'Certificate does not exist' unless current_cert
        acm.delete_certificate(certificate_arn: current_cert.certificate_arn)
      end

      def check_certificate
        current_cert = acm.list_certificates.certificate_summary_list.find do |cert|
          cert.domain_name == @domain
        end
        raise 'Certificate already exist' if current_cert
      end

      def acm
        @acm ||= Aws::ACM::Client.new
      end
    end
  end
end
