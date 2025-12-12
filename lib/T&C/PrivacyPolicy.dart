import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Last Updated
              Center(
                child: Text(
                  'Last updated on 7th November 2025',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF4B5563),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // Title
              Center(
                child: Text(
                  'PRIVACY POLICY',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF4B5563),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This Privacy Policy is published in compliance with the Information Technology Act 2000 its Rules and the Reasonable Security Practices and Procedures and Sensitive Personal Information Rules 2011 the SPI Rules as amended from time to time Your use of the Flyhub Platform is governed by this Privacy Policy and the Terms of Use indicated on the Platform',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Flyhubin including the online platforms mobile application web applications and software owned by Flytutor Technologies Private Limited including its subsidiaries hereinafter referred as Flyhub recognizes the importance of protecting your privacy Flyhub makes all reasonable endeavours to maintain the confidentiality integrity and security of all information of our users',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This Privacy Policy applies to all former current and all future till such time next updated visitors to the Platform ie our website and mobile applications and to the products and services of Flyhub offered to you Your access and use of the Platform confirms that you agree to this Privacy Policy In the event that you do not agree to this Privacy Policy we urge you not to access and use the Platform and products and services on the Platform',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This Privacy Policy describes how Flyhub collects and handles certain information it may collect andor receive from you via the use of the Platform mobile applications and other forms of interactions with you',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The privacy policies of other third parties who list their products and services on Flyhub Platform are governed by their separate terms and conditions You are advised to review those conditions independently and proceed with your interactions and engagements with those providers at your own responsibility',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // ELIGIBILITY
              Text(
                'ELIGIBILITY',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please access and use Flyhub Platform only if you are of the age of majority If you are accessing the Platform in India the age of majority is 18 years hence you should access the services on Flyhubin or our mobile and web applications only if you have attained the age of majority on the date of access and use of our services In the event that you are unable legally to enter into a valid contract including accepting this Privacy Policy we urge you not to use the Platform or the Services and in case you do it shall be your own legal responsibility and Flyhub and its management and employees are not obligated to comply with your directions or instructions or activities on Flyhub Platform',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // DEFINITIONS
              Text(
                'DEFINITIONS',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Applicable Laws shall mean the laws of India'),
              _buildBulletPoint('Platform means Flyhubin whether made available on the web or mobile app or in the social media or social media tools'),
              _buildBulletPoint('User means an individual or organisation that accesses Flyhub Platform or is a consumer of a Flyhub product or service'),
              _buildBulletPoint('Serviceservice means the products and services Flyhub makes available to a User on the Platform including drone purchase rental sales servicing drone parts and accessories training programs dronerelated news and information dronerelated job listings and pilot hiring services The services offered by third parties are separate and distinct from Flyhub services and governed by the conditions of the third parties'),
              const SizedBox(height: 32),

              // PERSONAL INFORMATION REQUESTED ON THE PLATFORM
              Text(
                'PERSONAL INFORMATION REQUESTED ON THE PLATFORM',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We may request you to provide your personal information such as name age mobile number email address bank details credit card details passport number Aadhar number where required under a government regulation pilot license details drone registration information employment history for job seekers and pilots professional certifications or other similar personal information necessary for the legitimate purpose of offering Services to you',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // AUTHORISATIONS AND CONSENT
              Text(
                'AUTHORISATIONS AND CONSENT',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'By accessing the Platform by using the services or providingmaking available information for use by us you agree to the practices and policies outlined in this Privacy Policy and you hereby consent to our collection use and sharing of information in the conditions described in this Privacy Policy as well as the General Conditions set forth on the Platform',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'BY USING THE PLATFORM ANDOR REGISTERING YOURSELF ON THE PLATFORM YOU EXPRESSLY CONSENT AND AUTHORIZE US AND ENTITIES WHO HAVE LISTED THEIR PRODUCTS AND SERVICES ON THE PLATFORM TO CONTACT YOU VIA EMAIL OR PHONE CALL OR SMS AND OFFER YOU SERVICES OR PRODUCTS YOU HAVE OPTED FOR OR THOSE THAT MAY BE RELEVANT FOR YOUR ENQUIRIES MADE ON THE PLATFORM INCLUDING DRONE PURCHASE RENTAL SALES SERVICE PARTS AND ACCESSORIES TRAINING JOB OPPORTUNITIES PILOT HIRING AND NEWS UPDATES YOU HEREBY AGREE AND AUTHORIZE US AND ENTITIES WHO HAVE LISTED THEIR PRODUCTS AND SERVICES ON THE PLATFORM TO CONTACT YOU FOR THE AFOREMENTIONED PURPOSES THIS CONSENT SHALL PREVAIL UPON ANY DND OR DNC OR NCPR SERVICES YOU MAY HAVE REGISTERED THIS IS ACCEPTED BY YOU AS A REASONABLE WAIVER IN CONSIDERATION OF THE MULTIPLE PRODUCT AND SERVICE OFFERINGS THAT YOU GAIN ACCESS TO ON FLYHUB PLATFORM YOUR AUTHORIZATION IN THIS REGARD SHALL BE VALID AS LONG AS YOUR ACCOUNT IS NOT DEACTIVATED BY EITHER YOU OR US',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'WE RESERVE THE RIGHT TO CHANGE MODIFY ADD OR DELETE PORTIONS OF THE TERMS OF THIS PRIVACY POLICY AT OUR SOLE DISCRETION AT ANY TIME',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'IF YOU DO NOT AGREE WITH THIS PRIVACY POLICY AT ANY TIME YOU SHOULD NOT USE THE PLATFORM',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // PERFORMING ACTIVITIES ON THE PLATFORM
              Text(
                'PERFORMING ACTIVITIES ON THE PLATFORM',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'If you are accessing for yourself registering your account or using the Platform on behalf of an individual other than yourself or an organisation you represent that you are authorized by such individualorganisation to accept this Privacy Policy on such individuals or organisations behalf and you are capable of enforcing the conditions contained herein upon such an individual or organisation',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Any User may visit the Platform without revealing Personally Identifiable Information for the fields permissible to be accessed without identifying oneself However in order to access the mobile application purchase or rent drones buy parts and accessories book services or training apply for jobs hire pilots or download certain resources on the Platform a User will need to provide certain personal information You understand and agree that downloadable resources at Flyhub where details such as Email or Mobile number are sought are essential to ensure that the content which is intellectual property of Flyhub or its third parties are reasonably and lawfully used by a User with a verified identity',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // HOW PERSONAL INFORMATION MAY BE PROCESSED BY FLYHUB
              Text(
                'HOW PERSONAL INFORMATION MAY BE PROCESSED BY FLYHUB',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We may track certain NonPersonally Identifiable Information for analytics and statistics These details are essentially used to understand trends and provide better services',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We may track and process data about your use of our Platform and the services offered therein usage data Such data may include your IP address geographical location browser type and version operating system referral source length of visit page views and website navigation paths as well as information about the timing frequency and pattern of your service use This usage data may be processed for the purposes of analysing the use of the Platform and the Services We may use third party analytics and tracking platforms and thus all such data and information collected by us may be processed or stored by the relevant thirdparty',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We may use APIs provided by third parties including but not limited to drone manufacturers parts suppliers service providers training institutions job portals payment processors and other third parties thus personal data relevant to the APIserviceproduct availed by you may be shared with such third parties to which you herein consent',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Some of the other data collected by us may include',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),

              // Cookies
              Text(
                'Cookies',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cookies are small pieces of information saved by the browsers It is possible for you to set your browser to notify you whenever a cookie is sent to you giving you the option to decide whether or not to accept it Some of the web pages on our website may use cookies to serve you customized contents for your return visits to our website Cookies also help us in authentication enhancement of security display targeted advertisements and most importantly help us in future enhancements on the website and Platform We use cookies on our Platform to see how people use the Platform and to keep a record of whether you accept cookies',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),

              // Log files
              Text(
                'Log files',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We keep log files This information may include internet protocol IP addresses browser type internet service provider ISP referringexit pages datetime stamp and number of clicks to gather broad demographic information for aggregate use We may combine this automatically collected log information with other information we collect about you',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),

              // Web beacons
              Text(
                'Web beacons',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'In limited circumstances we also may use Web Beacons to collect anonymous nonpersonal information about your use of our Platform and the sites of selected sponsors and advertisers and your use of emails special promotions or newsletters we send to you Web Beacons are tiny graphic image files imbedded in a web page or email that provide a presence on the web page or email and send back to its home server information from the users browser The information collected by web beacons allows us to statistically monitor how many people are using the Platform and selected sponsors and advertisers sites or opening our emails and for what purposes',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),

              // Registration data
              Text(
                'Registration data',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'In order for you to access the Platform andor the Services you will be required to provide us with certain information that personally identifies the person such information belongs to Personal Information Personal Information includes the following categories of information Contact Data such as email address phone number and user idpassword and Registration Data such as name gender drone license details training certifications employment history and professional qualifications These include usage of thirdparty signon mechanisms such as through your GoogleFacebook accounts or other social media log in',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),

              // Geolocation
              Text(
                'Geolocation',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'In order for you to avail the Services including finding nearby drone service centers training facilities rental locations parts suppliers or job opportunities you will be required to provide us with your geolocation also',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // INFORMATION COLLECTED BY MOBILE APPLICATION AND WEB APPLICATION
              Text(
                'INFORMATION COLLECTED BY MOBILE APPLICATION AND WEB APPLICATION',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Our Services are provided through the Mobile application and Web application We may collect and use such technical data and related information including but not limited to technical information about your device system and application software and peripherals that is gathered periodically to facilitate the provision of software updates product support and other services to you if any related to such Mobile Applications',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'When you use any of our Mobile or Web application the applications may automatically collect and store some or all of the following information from your mobile device or computer device Device Information in addition to the Device Information including without limitation may be collected',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('The manufacturer and model of your mobile or computer device'),
              _buildBulletPoint('Your mobile or computer operating system'),
              _buildBulletPoint('The type of internet browsers you are using'),
              _buildBulletPoint('Your geolocation'),
              _buildBulletPoint('Information about how you interact with the Mobile or Web application and any of our websites to which the Flyhub application links such as how many times you use a specific part of the application over a given time period the amount of time you spend using the application how often you use the application actions you take in the application and how you engage with the application'),
              _buildBulletPoint('Information to allow us to personalize the services and content available through the application'),
              _buildBulletPoint('Data from SMStext messages upon receiving device permissions for the purposes of i issuing and receiving onetime passwords and other device verification and ii automatically filling verification details during financial transactions either through us or a thirdparty service provider in accordance with applicable law We do not share or transfer SMStext message data to any third party other than as provided under this Privacy Policy'),
              const SizedBox(height: 32),

              // YOUR CONTROL OVER YOUR PERSONAL INFORMATION
              Text(
                'YOUR CONTROL OVER YOUR PERSONAL INFORMATION',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You have the right to have any inaccurate personal or registration data about you rectified and have incomplete data about you completed You can view your Personal Information in your account at any time and update it as necessary using your username and your password Once we are informed we will adjust incorrect data accordingly',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'In the event you desire to withdraw consent to our processing of your information kindly contact our GrievancePrivacy Officer at salesflyhubin and we will cease to process the information unless we have legitimate grounds for the processing which override your interests rights and freedoms or the processing is for the establishment exercise or defence of legal claims',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Further upon your request Flyhub will use commercially reasonable efforts to delete your account from the Platform and the information in your profile relating to the Platform however it may be impossible to remove your account without some residual information being retained by Flyhub for legal or regulatory compliance',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // DATA PROCESSING
              Text(
                'DATA PROCESSING',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We may process your information included in your profile on the Platform including the Personal Information This data along with any other electronic record generated is held by Flyhub in trust on your behalf for the duration of your usage of the Services and for periods thereafter as requiredpermissible under the Applicable Laws',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We may process data about your use of our Platform and the services offered therein The usage data may include your internet protocol address geographical location browser type and version operating system referral source length of visit page views and website navigation paths as well as information about the timing frequency and pattern of your use The source of such data are thirdparty analytics platforms This data may be processed for the purposes of analysing the use of the Platform and services',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We may also process information contained in any enquiry you submit to us regarding Services or contained in or relating to any communication that you send to us pertaining to the Platform The correspondence data may include the communication content and metadata associated with the communication',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We may process any of your data identified in the other provisions of this Policy where necessary for the establishment exercise or defence of legal claims whether in court proceedings or in an administrative or outofcourt procedure In addition to the specific purposes for which we may process your personal data set out we may also process any of your personal data where such processing is necessary for compliance with a legal obligation to which we are subject or in order to protect your vital interests or the vital interests of another natural person',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We may use your Personal Information and contact information such as mobile number and emails that you provide to make recommendations of products and services share updates about new drone models parts and accessories training programs service offers job opportunities pilot hiring opportunities promotional campaigns seek feedback know your preferences identify the appropriate third parties for your requirements We may use your Registration Data and other information to identify or interact with you on social media We also use your Registration Data to send you information about other products and services on the Platform or those of our listed third parties or to contact you when necessary',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We may use your geolocation to provide services to you including locating nearby service centers rental facilities training locations parts suppliers and job opportunities',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We may use your data to customize and tailor your experience on the Platform in emails and in other communications displaying content that we think you might be interested in and according to your preferences',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Without limitation to the foregoing your information may be used',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('To facilitate drone purchase rental bookings service appointments parts and accessories orders training enrollment job applications and pilot hiring'),
              _buildBulletPoint('To connect buyers and sellers employers and job seekers clients and pilots within the drone ecosystem'),
              _buildBulletPoint('To provide information about available drones spare parts accessories and related products'),
              _buildBulletPoint('To schedule and manage drone servicing and maintenance'),
              _buildBulletPoint('To enroll users in training programs and certification courses'),
              _buildBulletPoint('To post and manage job listings and pilot profiles'),
              _buildBulletPoint('To match qualified pilots with hiring opportunities'),
              _buildBulletPoint('To deliver dronerelated news updates and industry information'),
              _buildBulletPoint('To develop enhance market sell or provide our products or services or those of companies with which we have a commercial relationship'),
              _buildBulletPoint('To communicate information and respond pertaining to your inquiries'),
              _buildBulletPoint('To issue invoices administer accounts collect and process payments'),
              _buildBulletPoint('To provide tips or guidance on how to use Platform the facilities we offer inform you of new features or provide other information that may be of interest to you'),
              _buildBulletPoint('To personalize the service we provide to you tailor your experience to your requirements and make more appropriate recommendations'),
              _buildBulletPoint('To send you emails enewsletters personalized offers via direct messaging or other communications about our services'),
              _buildBulletPoint('To collect feedback on sellers service providers trainers employers pilots Users the Platform or the Service'),
              _buildBulletPoint('To process and track your transactions and to send you information about Us our affiliates sellers service providers and business partners products and services and other information and materials that may be of interest to you'),
              _buildBulletPoint('To audit compliance with our policies contractual and statutory obligations'),
              _buildBulletPoint('To prevent fraudulent transactions on the Platform'),
              _buildBulletPoint('To make and collect payments from Users sellers and service providers'),
              _buildBulletPoint('To analyse software usage patterns for improving product design and utility'),
              _buildBulletPoint('To analyse anonymized practice information for commercial use and'),
              _buildBulletPoint('As permitted by and to comply with any legal or regulatory requirements or provisions or for any other purpose to which you consent'),
              const SizedBox(height: 32),

              // DISCLOSURE OF INFORMATION
              Text(
                'DISCLOSURE OF INFORMATION',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Except as described in this Policy we will not without your consent disclose information about you However we may disclose information to third parties as well as in the following circumstances',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Any information that you voluntarily choose to include in a publicly accessible area of the Platform will be available to anyone who has access to that content including other Users sellers service providers trainers employers and pilots'),
              _buildBulletPoint('When it is requested or required by law or by any court or governmental agency or authority to disclose for the purpose of verification of identity or for the prevention detection investigation including cyber incidents or for prosecution and punishment of offences These disclosures are made in good faith and belief that such disclosure is reasonably necessary for enforcing these Terms and Conditions for complying with the applicable laws and regulations'),
              _buildBulletPoint('Where we need to comply with a legal obligation as per applicable legal and regulatory framework'),
              _buildBulletPoint('We will disclose information about you to sellers service providers trainers employers pilots and other Third Parties to assist you with drone purchases rentals parts and accessories orders servicing training enrollment job applications pilot hiring or other services offered on the Platform'),
              _buildBulletPoint('To enable listed third parties on our Platform to offer you their products and services as Flyhub is a multivendor Platform to provide products and services to drone users and participants in the drone ecosystem We may work with thirdparty service providers to provide various services These thirdparty service providers may have access to or process information about you as part of providing those services for us Generally we limit the information provided to these service providers to that which is reasonably necessary for them to perform their functions and we require them to agree to maintain the confidentiality of such information'),
              _buildBulletPoint('We may disclose information about you if required to do so by law or in the goodfaith belief that such action is necessary to comply with state and central laws in response to a court order judicial or other government subpoena or warrant or to otherwise cooperate with law enforcement or other governmental agencies'),
              _buildBulletPoint('Further as we use third party platforms or clouds provided by Google AWS Microsoft Azure or similar such entities all data and information collected by us shall be stored on such platforms or clouds You agree and acknowledge that data loss or data breach occurring at such service providers platforms or clouds are beyond Flyhubs control for which you shall not hold Flyhub responsible'),
              _buildBulletPoint('We also reserve the right to disclose information about you that we believe in good faith is appropriate or necessary to i take precautions against liability ii protect ourselves or others from fraudulent abusive or unlawful uses or activity iii investigate and defend ourselves against any thirdparty claims or allegations iv protect the security or integrity of the Service and any facilities or equipment used to make the Service available v protect our property or other legal rights including but not limited to enforcement of our agreements or the rights property or safety of others'),
              _buildBulletPoint('Information about our users may be disclosed and otherwise transferred to an acquirer successor or assignee as part of any merger acquisition debt financing sale of assets or similar transaction or in the event of any insolvency bankruptcy or receivership in which information is transferred to one or more third parties as one of our business assets'),
              _buildBulletPoint('We may make certain aggregated automaticallycollected or otherwise nonpersonal information available to third parties for various purposes including i compliance with various reporting obligations ii for business or marketing purposes or iii to assist such parties in understanding our users interests habits and usage patterns for certain programs content services advertisements promotions andor functionality available through the Service'),
              const SizedBox(height: 32),

              // DATA SECURITY
              Text(
                'DATA SECURITY',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We follow generally accepted industry standards to protect the information submitted to us both during transmission and once we receive it For example we take physical and electronic processspecific security measures including firewalls personal passwords and encryption and authentication technologies',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Such measures include but are not limited to secure sockets layer encryption routine security audits and scans routine updating and patching of all servers services and applications as well as usage of code intended to block sql injection attacks',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Although we make good faith efforts to store Personal Information in a secure operating environment that is not open to the public you acknowledge that there is no absolute security possible Data breach or cyberattacks or events outside the control of Flyhub may happen for which you shall not hold Flyhub responsible We do not guarantee there will be no unintended disclosures of your Personal Information If we become aware that your Personal Information has been disclosed in a manner not in accordance with this Privacy Policy we will use reasonable efforts to notify you of the nature and extent of the disclosure to the extent we know that information as soon as reasonably possible and as permitted by law',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // DATA RETENTION
              Text(
                'DATA RETENTION',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'As a general rule the personal data that is processed by us as set forth herein is not retained for longer than necessary for the purpose for which it was processed Personal Information shall be retained till such time as you continue to avail our Services or for a period as required by the Applicable Law following which an aggregate version or any other form of structured data thereof may be retained',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We determine the period of retention based on the period we need to access the data for the provision of Services receiving payment resolving business or other issues or any other auditing or legal reasons Further notwithstanding anything to the contrary we shall have the right to retain your personal data where such retention is necessary for compliance with any legal or regulatory obligation to which we are subject or in order to protect your vital interests or the vital interests of another natural person or interests of Flyhub',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // THIRDPARTY SERVICES
              Text(
                'THIRDPARTY SERVICES',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The Platform contains features or links to other websites other platforms other applications and services provided by third parties including services and products provided by drone manufacturers sellers service providers trainers employers and pilots Any information you provide on thirdparty sites or services is provided directly to the operators of such services and is subject to those operators policies if any governing privacy and security even if accessed through the Flyhub Platform We are not responsible for the content or privacy and security practices and policies of thirdparty sites or services to which links or access are provided through the Flyhub Platform We encourage you to learn about third parties privacy and security policies before providing them with information',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // POLICIES AND ACTIONS OF THIRD PARTIES
              Text(
                'POLICIES AND ACTIONS OF THIRD PARTIES',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Flyhub its management directors or employees are not responsible for the acts omissions or breaches pertaining to your personal information in the course of their interactions or engagements with you You hereby release Flyhub of any liability or responsibility of such acts or consequences of such acts of third parties who are listed on the Flyhub Platform We endeavour to mandate to such parties to always comply with the Applicable Laws however you are required to make yourself aware of privacy policies of such third parties independently The policies of third parties shall apply to you when you engage with them to assess or buy their products or services so you are urged to carefully review and understand them Flyhub is not responsible for any policies of third parties including policies they implement to collect store or retain your personal information',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // OPT OUT
              Text(
                'OPT OUT',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'If you are no longer interested in receiving information from Flyhub please email your request at salesflyhubin Please note that it may take about 10 days to process your request In the event you do not want to receive any information from the third parties listed on our Platform you are required to follow their Optout procedures separately',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // SECURITY MEASURES AT FLYHUB
              Text(
                'SECURITY MEASURES AT FLYHUB',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We employ reasonable technical and organizational security measures at all times to protect the information we collect from you We may use multiple electronic procedural and physical security measures to protect against unauthorized or unlawful use or alteration of information and against any accidental loss destruction or damage to information However no method of transmission over the Internet or method of electronic storage is 100 secure Therefore we cannot guarantee its absolute security Further you are responsible for maintaining the confidentiality and security of your login id and password and may not provide these credentials to anyone else You hereby release Flyhub of any claims or actions related to a security breach data breach cyber security event caused by reasons outside Flyhubs own actions or breaches or caused by a third party or as a result of a cause outside Flyhubs reasonable control or prevention protocols',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // LINKS TO OTHER WEBSITES APPLICATIONS PLATFORMS
              Text(
                'LINKS TO OTHER WEBSITES APPLICATIONS PLATFORMS',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'There might be other sites applications and platforms linked to Flyhub Platform Personal information that you provide to those sites applications or platforms are not our property These affiliated sites may have different privacy practices and we encourage you to read their privacy policies of these websites when you visit them For the interactions and engagements you undertake with such linked websites applications or the service providers Flyhub takes no responsibility for their acts omissions breach of privacy or data breach by such entities',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // UPDATES AND CHANGES TO PRIVACY POLICY
              Text(
                'UPDATES AND CHANGES TO PRIVACY POLICY',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We may update this Privacy Policy at any time with or without advance notice In the event there are significant changes in the way we treat Users personally identifiable information or in the Privacy Policy itself we will display a notice on the Platform or at our sole discretion send Users an email as provided for above so that you may review the changed terms prior to continuing to use the Services',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // GOVERNING LAWS
              Text(
                'GOVERNING LAWS',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Flyhub Platform currently is primarily organised to provide products and services to the drone ecosystem in India The governing laws applicable shall be laws of India Applicable Laws and the exclusive jurisdiction of courts in Bangalore shall lie for any disputes The laws and jurisdiction shall be notwithstanding any conflict in law principles',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // GRIEVANCE OFFICER
              Text(
                'GRIEVANCE OFFICER',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'In accordance with Information Technology Act 2000 and rules made thereunder the name and contact details of the Grievance Officer are provided below',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Name Privacy Officer Flytutor Technologies Private Limited',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email salesflyhubin',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Contact Hours Monday to Friday 1000 AM to 600 PM IST',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // CONCLUSION
              Text(
                'CONCLUSION',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We use processes systems and good practices to the extent commercially reasonable to protect the personal information you provide or make available to us If you have any comments questions or concerns about this policy or how we store process and use data please reach out to GrievancePrivacy Officer at salesflyhubin',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Note
              Text(
                'Note This Privacy Policy and Flyhub privacy practices are designed considering the laws of India and the market of India If you are located in a country outside India where you may be subject to specific privacy laws such as GDPR or others you are requested to connect with the Privacy Officer above mentioned by an email and we shall guide you how to access the products services reports newsletters etc for instances where your personal information may be required as an essential condition to verify identity or access resources at Flyhub.in',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Final divider
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8, right: 8),
            child: Text(
              '•',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}