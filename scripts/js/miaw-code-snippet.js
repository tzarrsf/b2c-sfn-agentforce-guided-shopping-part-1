<script>
 var initESW = function(gslbBaseURL) { ... };
embeddedservice_bootstrap.init(
    '00Dbm00000XXXX',  // ← salesforceOrgId
    'zzpe110_Shopper_Agent',  // ← embeddedServiceName
    'https://….my.site.com/ESWExampleShopperAgent',  // ← embeddedServiceEndpoint
    { scrt2URL: 'https://...' }  // ← scrt2Url
);

// And from the script tag:
src='https://trailsignup-5e845b80229084.my.site.com/.../bootstrap.min.js'  // ← scriptSourceUrl

</script>