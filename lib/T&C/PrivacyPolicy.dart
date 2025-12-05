import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last Updated
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Last updated on 7th November, 2025',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Introduction
            _buildSectionTitle('Introduction'),
            const SizedBox(height: 8),
            _buildParagraph(
                'This Privacy Policy is published in compliance with the Information Technology Act, 2000, its Rules and the Reasonable Security Practices and Procedures and Sensitive Personal Information Rules, 2011 (the "SPI Rules") as amended from time to time. Your use of the Flyhub Platform is governed by this Privacy Policy and the Terms of Use indicated on the Platform.'
            ),
            const SizedBox(height: 12),
            _buildParagraph(
                'Flyhub.in including the online platform(s), mobile application, web applications and software owned by Flytutor Technologies Private Limited including its subsidiaries hereinafter referred as "Flyhub" recognizes the importance of protecting your privacy. Flyhub makes all reasonable endeavours to maintain the confidentiality, integrity and security of all information of our users.'
            ),
            const SizedBox(height: 12),
            _buildParagraph(
                'This Privacy Policy applies to all former, current, and all future visitors to the Platform i.e. our website and mobile applications and to the products and services of Flyhub offered to you. Your access and use of the Platform confirms that you agree to this Privacy Policy. In the event that you do not agree to this Privacy Policy, we urge you not to access and use the Platform and products and services on the Platform.'
            ),

            // Eligibility
            const SizedBox(height: 24),
            _buildSectionTitle('Eligibility'),
            const SizedBox(height: 8),
            _buildParagraph(
                'Please access and use Flyhub Platform only if you are of the age of majority. If you are accessing the Platform in India, the age of majority is 18 years, hence you should access the services on Flyhub.in or our mobile and web applications only if you have attained the age of majority on the date of access and use of our services.'
            ),

            // Definitions
            const SizedBox(height: 24),
            _buildSectionTitle('Definitions'),
            const SizedBox(height: 8),
            _buildBulletPoint('Applicable Laws shall mean the laws of India.'),
            const SizedBox(height: 4),
            _buildBulletPoint('Platform means Flyhub.in whether made available on the web or mobile app or in the social media or social media tools.'),
            const SizedBox(height: 4),
            _buildBulletPoint('User means an individual or organisation that accesses Flyhub Platform or is a consumer of a Flyhub product or service.'),
            const SizedBox(height: 4),
            _buildBulletPoint('Service/service means the products and services Flyhub makes available to a User on the Platform, including drone purchase, rental, sales, servicing, drone parts and accessories, training programs, drone-related news and information, drone-related job listings, and pilot hiring services.'),

            // Personal Information Requested
            const SizedBox(height: 24),
            _buildSectionTitle('Personal Information Requested on the Platform'),
            const SizedBox(height: 8),
            _buildParagraph(
                'We may request you to provide your personal information such as name, age, mobile number, email, address, bank details, credit card details, passport number, Aadhar number (where required under a government regulation), pilot license details, drone registration information, employment history (for job seekers and pilots), professional certifications, or other similar personal information necessary for the legitimate purpose of offering Services to you.'
            ),

            // Authorizations and Consent
            const SizedBox(height: 24),
            _buildSectionTitle('Authorizations and Consent'),
            const SizedBox(height: 8),
            _buildParagraph(
                'By accessing the Platform, by using the services or providing/making available information for use by us, you agree to the practices and policies outlined in this Privacy Policy and you hereby consent to our collection, use and sharing of information in the conditions described in this Privacy Policy as well as the General Conditions set forth on the Platform.'
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                  'BY USING THE PLATFORM AND/OR REGISTERING YOURSELF ON THE PLATFORM YOU EXPRESSLY CONSENT AND AUTHORIZE US AND ENTITIES WHO HAVE LISTED THEIR PRODUCTS AND SERVICES ON THE PLATFORM TO CONTACT YOU VIA EMAIL OR PHONE CALL OR SMS AND OFFER YOU SERVICES OR PRODUCTS YOU HAVE OPTED FOR OR THOSE THAT MAY BE RELEVANT FOR YOUR ENQUIRIES MADE ON THE PLATFORM, INCLUDING DRONE PURCHASE, RENTAL, SALES, SERVICE, PARTS AND ACCESSORIES, TRAINING, JOB OPPORTUNITIES, PILOT HIRING, AND NEWS UPDATES. YOU HEREBY AGREE AND AUTHORIZE US AND ENTITIES WHO HAVE LISTED THEIR PRODUCTS AND SERVICES ON THE PLATFORM TO CONTACT YOU FOR THE AFOREMENTIONED PURPOSES. THIS CONSENT SHALL PREVAIL UPON ANY DND OR DNC OR NCPR SERVICE(S) YOU MAY HAVE REGISTERED. THIS IS ACCEPTED BY YOU AS A REASONABLE WAIVER IN CONSIDERATION OF THE MULTIPLE PRODUCT AND SERVICE OFFERINGS THAT YOU GAIN ACCESS TO ON FLYHUB PLATFORM. YOUR AUTHORIZATION, IN THIS REGARD, SHALL BE VALID AS LONG AS YOUR ACCOUNT IS NOT DEACTIVATED BY EITHER YOU OR US.'
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                  'WE RESERVE THE RIGHT TO CHANGE, MODIFY, ADD OR DELETE PORTIONS OF THE TERMS OF THIS PRIVACY POLICY, AT OUR SOLE DISCRETION, AT ANY TIME.'
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                  'IF YOU DO NOT AGREE WITH THIS PRIVACY POLICY AT ANY TIME, YOU SHOULD NOT USE THE PLATFORM.'
              ),
            ),

            // Performing Activities on the Platform
            const SizedBox(height: 24),
            _buildSectionTitle('Performing Activities on the Platform'),
            const SizedBox(height: 8),
            _buildParagraph(
                'If you are accessing for yourself, registering your account or using the Platform on behalf of an individual other than yourself or an organisation, you represent that you are authorized by such individual/organisation to accept this Privacy Policy on such individual\'s or organisation\'s behalf and you are capable of enforcing the conditions contained herein upon such an individual or organisation.'
            ),
            const SizedBox(height: 12),
            _buildParagraph(
                'Any User may visit the Platform without revealing Personally Identifiable Information for the fields permissible to be accessed without identifying oneself. However, in order to access the mobile application, purchase or rent drones, buy parts and accessories, book services or training, apply for jobs, hire pilots, or download certain resources on the Platform, a User will need to provide certain personal information.'
            ),

            // How Personal Information May Be Processed
            const SizedBox(height: 24),
            _buildSectionTitle('How Personal Information May Be Processed by Flyhub'),
            const SizedBox(height: 8),
            _buildBulletPoint('We may track certain Non-Personally Identifiable Information for analytics and statistics.'),
            const SizedBox(height: 4),
            _buildBulletPoint('We may track and process data about your use of our Platform and the services offered therein.'),
            const SizedBox(height: 4),
            _buildBulletPoint('We may use APIs provided by third parties including but not limited to drone manufacturers, parts suppliers, service providers, training institutions, job portals, payment processors, and other third parties.'),
            const SizedBox(height: 12),
            _buildSubTitle('1. Cookies'),
            const SizedBox(height: 8),
            _buildParagraph(
                'Cookies are small pieces of information saved by the browsers. It is possible for you to set your browser to notify you whenever a cookie is sent to you, giving you the option to decide whether or not to accept it. We use cookies on our Platform to see how people use the Platform and to keep a record of whether you accept cookies.'
            ),
            const SizedBox(height: 12),
            _buildSubTitle('2. Log files'),
            _buildParagraph(
                'We keep log files. This information may include internet protocol (IP) addresses, browser type, internet service provider (ISP), referring/exit pages, date/time stamp, and number of clicks to gather broad demographic information for aggregate use.'
            ),
            const SizedBox(height: 12),
            _buildSubTitle('3. Web beacons'),
            _buildParagraph(
                'In limited circumstances, we also may use Web Beacons to collect anonymous, non-personal information about your use of our Platform and the sites of selected sponsors and advertisers, and your use of emails, special promotions or newsletters we send to you.'
            ),
            const SizedBox(height: 12),
            _buildSubTitle('4. Registration data'),
            _buildParagraph(
                'In order for you to access the Platform and/or the Services, you will be required to provide us with certain information that personally identifies the person such information belongs to.'
            ),
            const SizedBox(height: 12),
            _buildSubTitle('5. Geolocation'),
            _buildParagraph(
                'In order for you to avail the Services, including finding nearby drone service centers, training facilities, rental locations, parts suppliers, or job opportunities, you will be required to provide us with your geolocation also.'
            ),

            // Information Collected by Mobile Application
            const SizedBox(height: 24),
            _buildSectionTitle('Information Collected by Mobile Application and Web Application'),
            const SizedBox(height: 8),
            _buildParagraph(
                'Our Services are provided through the Mobile application and Web application. We may collect and use such technical data and related information, including but not limited to, technical information about your device, system and application software, and peripherals.'
            ),
            const SizedBox(height: 12),
            _buildParagraph(
                'When you use any of our Mobile or Web application, the applications may automatically collect and store Device Information, including:'
            ),
            const SizedBox(height: 8),
            _buildNumberedPoint(1, 'The manufacturer and model of your mobile or computer device'),
            const SizedBox(height: 4),
            _buildNumberedPoint(2, 'Your mobile or computer operating system'),
            const SizedBox(height: 4),
            _buildNumberedPoint(3, 'The type of internet browsers you are using'),
            const SizedBox(height: 4),
            _buildNumberedPoint(4, 'Your geolocation'),
            const SizedBox(height: 4),
            _buildNumberedPoint(5, 'Information about how you interact with the Mobile or Web application'),
            const SizedBox(height: 4),
            _buildNumberedPoint(6, 'Information to allow us to personalize the services and content'),
            const SizedBox(height: 4),
            _buildNumberedPoint(7, 'Data from SMS/text messages upon receiving device permissions for verification purposes'),

            // Your Control Over Personal Information
            const SizedBox(height: 24),
            _buildSectionTitle('Your Control Over Your Personal Information'),
            const SizedBox(height: 8),
            _buildParagraph(
                'You have the right to have any inaccurate personal or registration data about you rectified and have incomplete data about you completed. You can view your Personal Information in your account at any time and update it as necessary using your username and your password.'
            ),
            const SizedBox(height: 12),
            _buildParagraph(
                'In the event you desire to withdraw consent to our processing of your information, kindly contact our Grievance/Privacy Officer at sales@flyhub.in.'
            ),

            // Data Processing
            const SizedBox(height: 24),
            _buildSectionTitle('Data Processing'),
            const SizedBox(height: 8),
            _buildParagraph(
                'We may process your information included in your profile on the Platform, including the Personal Information. This data along with any other electronic record generated is held by Flyhub in trust, on your behalf, for the duration of your usage of the Services and for periods thereafter as required/permissible under the Applicable Laws.'
            ),
            const SizedBox(height: 12),
            _buildParagraph(
                'We may process data about your use of our Platform and the services offered therein. The usage data may include your internet protocol address, geographical location, browser type and version, operating system, referral source, length of visit, page views and website navigation paths.'
            ),
            const SizedBox(height: 12),
            _buildParagraph(
                'We may also process information contained in any enquiry you submit to us regarding Services or contained in or relating to any communication that you send to us pertaining to the Platform.'
            ),
            const SizedBox(height: 12),
            _buildParagraph(
                'We may use your Personal Information and contact information such as mobile number and emails that you provide to make recommendations of products and services, share updates about new drone models, parts and accessories, training programs, service offers, job opportunities, pilot hiring opportunities, promotional campaigns, seek feedback, know your preferences.'
            ),

            // Disclosure of Information
            const SizedBox(height: 24),
            _buildSectionTitle('Disclosure of Information'),
            const SizedBox(height: 8),
            _buildParagraph(
                'Except as described in this Policy, we will not, without your consent, disclose information about you. However, we may disclose information to third parties as well as in the following circumstances:'
            ),
            const SizedBox(height: 12),
            _buildNumberedPoint(1, 'Any information that you voluntarily choose to include in a publicly accessible area of the Platform will be available to anyone who has access to that content.'),
            const SizedBox(height: 8),
            _buildNumberedPoint(2, 'When it is requested or required by law or by any court or governmental agency or authority to disclose.'),
            const SizedBox(height: 8),
            _buildNumberedPoint(3, 'Where we need to comply with a legal obligation as per applicable legal and regulatory framework.'),
            const SizedBox(height: 8),
            _buildNumberedPoint(4, 'We will disclose information about you to sellers, service providers, trainers, employers, pilots, and other Third Parties to assist you with drone purchases, rentals, parts and accessories orders, servicing, training enrollment, job applications, pilot hiring, or other services offered on the Platform.'),
            const SizedBox(height: 8),
            _buildNumberedPoint(5, 'To enable listed third parties on our Platform to offer you their products and services as Flyhub is a multi-vendor Platform.'),
            const SizedBox(height: 8),
            _buildNumberedPoint(6, 'We may disclose information about you if required to do so by law or in the good-faith belief that such action is necessary to comply with state and central laws.'),

            // Data Security
            const SizedBox(height: 24),
            _buildSectionTitle('Data Security'),
            const SizedBox(height: 8),
            _buildParagraph(
                'We follow generally accepted industry standards to protect the information submitted to us, both during transmission and once we receive it. For example, we take physical and electronic process-specific security measures, including firewalls, personal passwords, and encryption and authentication technologies.'
            ),
            const SizedBox(height: 12),
            _buildParagraph(
                'Although we make good faith efforts to store Personal Information in a secure operating environment that is not open to the public, you acknowledge that there is no absolute security possible. Data breach or cyber-attacks or events outside the control of Flyhub may happen for which you shall not hold Flyhub responsible.'
            ),

            // Data Retention
            const SizedBox(height: 24),
            _buildSectionTitle('Data Retention'),
            const SizedBox(height: 8),
            _buildParagraph(
                'As a general rule, the personal data that is processed by us as set forth herein is not retained for longer than necessary for the purpose for which it was processed. Personal Information shall be retained till such time as you continue to avail our Services or for a period as required by the Applicable Law.'
            ),

            // Third-Party Services
            const SizedBox(height: 24),
            _buildSectionTitle('Third-Party Services'),
            const SizedBox(height: 8),
            _buildParagraph(
                'The Platform contains features or links to other websites, other platforms, other applications and services provided by third parties, including services and products provided by drone manufacturers, sellers, service providers, trainers, employers, and pilots.'
            ),

            // Opt Out
            const SizedBox(height: 24),
            _buildSectionTitle('Opt Out'),
            const SizedBox(height: 8),
            _buildParagraph(
                'If you are no longer interested in receiving information from Flyhub, please e-mail your request at: sales@flyhub.in. Please note that it may take about 10 days to process your request. In the event you do not want to receive any information from the third parties listed on our Platform, you are required to follow their Opt-out procedures separately.'
            ),

            // Security Measures
            const SizedBox(height: 24),
            _buildSectionTitle('Security Measures at Flyhub'),
            const SizedBox(height: 8),
            _buildParagraph(
                'We employ reasonable technical and organizational security measures at all times to protect the information we collect from you. We may use multiple electronic, procedural, and physical security measures to protect against unauthorized or unlawful use or alteration of information, and against any accidental loss, destruction, or damage to information.'
            ),

            // Updates and Changes
            const SizedBox(height: 24),
            _buildSectionTitle('Updates and Changes to Privacy Policy'),
            const SizedBox(height: 8),
            _buildParagraph(
                'We may update this Privacy Policy at any time, with or without advance notice. In the event there are significant changes in the way we treat User\'s personally identifiable information, or in the Privacy Policy itself, we will display a notice on the Platform or at our sole discretion send Users an email.'
            ),

            // Governing Laws
            const SizedBox(height: 24),
            _buildSectionTitle('Governing Laws'),
            const SizedBox(height: 8),
            _buildParagraph(
                'Flyhub Platform currently is primarily organised to provide products and services to the drone ecosystem in India. The governing laws applicable shall be laws of India (Applicable Laws) and the exclusive jurisdiction of courts in Bangalore shall lie for any disputes.'
            ),

            // Grievance Officer
            const SizedBox(height: 24),
            _buildSectionTitle('Grievance Officer'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildParagraph('Name: Privacy Officer, Flytutor Technologies Private Limited'),
                  const SizedBox(height: 8),
                  _buildParagraph('Email: sales@flyhub.in'),
                  const SizedBox(height: 8),
                  _buildParagraph('Contact Hours: Monday to Friday (10:00 AM to 6:00 PM IST)'),
                ],
              ),
            ),

            // Conclusion
            const SizedBox(height: 24),
            _buildSectionTitle('Conclusion'),
            const SizedBox(height: 8),
            _buildParagraph(
                'We use processes, systems and good practices (to the extent commercially reasonable) to protect the personal information you provide or make available to us. If you have any comments, questions or concerns about this policy or how we store, process and use data, please reach out to Grievance/Privacy Officer at sales@flyhub.in'
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                  'Note: This Privacy Policy and Flyhub\'s privacy practices are designed considering the laws of India and the market of India. If you are located in a country outside India where you may be subject to specific privacy laws, such as GDPR or others, you are requested to connect with the Privacy Officer above mentioned by an email.'
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildSubTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 14)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberedPoint(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$number. ', style: const TextStyle(fontSize: 14)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}