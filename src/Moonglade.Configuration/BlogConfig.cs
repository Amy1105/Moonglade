﻿using Newtonsoft.Json;

namespace Moonglade.Configuration
{
    public class BlogConfig
    {
        public BlogOwnerSettings BlogOwnerSettings { get; set; }

        public GeneralSettings GeneralSettings { get; set; }

        public ContentSettings ContentSettings { get; set; }

        public EmailConfiguration EmailConfiguration { get; set; }

        public FeedSettings FeedSettings { get; set; }

        public WatermarkSettings WatermarkSettings { get; set; }

        private bool _hasInitialized;

        public BlogConfig()
        {
            BlogOwnerSettings = new BlogOwnerSettings();
            ContentSettings = new ContentSettings
            {
                DisharmonyWords = string.Empty,
                EnableComments = true
            };
            GeneralSettings = new GeneralSettings();
            EmailConfiguration = new EmailConfiguration();
            FeedSettings = new FeedSettings();
            WatermarkSettings = new WatermarkSettings();
        }

        public void GetConfiguration(BlogConfigurationService blogConfigurationService)
        {
            if (!_hasInitialized)
            {
                var cfgDic = blogConfigurationService.GetAllConfigurations();

                BlogOwnerSettings = JsonConvert.DeserializeObject<BlogOwnerSettings>(cfgDic[nameof(BlogOwnerSettings)]);
                GeneralSettings = JsonConvert.DeserializeObject<GeneralSettings>(cfgDic[nameof(GeneralSettings)]);
                ContentSettings = JsonConvert.DeserializeObject<ContentSettings>(cfgDic[nameof(ContentSettings)]);

                EmailConfiguration = JsonConvert.DeserializeObject<EmailConfiguration>(cfgDic[nameof(EmailConfiguration)]);
                if (!string.IsNullOrWhiteSpace(EmailConfiguration.SmtpPassword))
                {
                    EmailConfiguration.SmtpPassword =
                        blogConfigurationService.DecryptPassword(EmailConfiguration.SmtpPassword);
                }

                FeedSettings = JsonConvert.DeserializeObject<FeedSettings>(cfgDic[nameof(FeedSettings)]);
                WatermarkSettings = JsonConvert.DeserializeObject<WatermarkSettings>(cfgDic[nameof(WatermarkSettings)]);

                _hasInitialized = true;
            }
        }

        public void DumpOldValuesWhenNextLoad()
        {
            _hasInitialized = false;
        }
    }
}