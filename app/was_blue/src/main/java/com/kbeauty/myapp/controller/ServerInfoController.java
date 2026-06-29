package com.kbeauty.myapp.controller;

import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.URL;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Scanner;

import javax.sql.DataSource;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class ServerInfoController {

    private static final long CACHE_TTL_MILLIS = 60_000;
    private static final long DB_HOST_CACHE_TTL_MILLIS = 10 * 60_000;
    private static final int METADATA_TIMEOUT_MILLIS = 250;
    private static final String APP_COLOR = "blue";
    private static final String AWS_METADATA_BASE_URL = "http://169.254.169.254/latest";
    private static final String AZURE_METADATA_BASE_URL = "http://169.254.169.254/metadata/instance";

    private final DataSource dataSource;
    private Map<String, String> cachedServerInfo;
    private long cachedAtMillis;
    private String cachedDbHost;
    private long cachedDbHostAtMillis;

    @GetMapping("/server-info")
    public Map<String, String> getServerInfo() {
        return new LinkedHashMap<>(getCachedServerInfo());
    }

    private synchronized Map<String, String> getCachedServerInfo() {
        long now = System.currentTimeMillis();
        if (cachedServerInfo != null && now - cachedAtMillis < CACHE_TTL_MILLIS) {
            return cachedServerInfo;
        }

        Map<String, String> info = new LinkedHashMap<>();
        String cloudProvider = valueOrDefault(System.getenv("CLOUD_PROVIDER"), detectCloudProvider());
        info.put("appColor", APP_COLOR);
        info.put("cloudProvider", cloudProvider);
        info.put("cloudZone", getCloudZone(cloudProvider));
        info.put("hostName", getHostName());
        info.put("serverIp", getServerIp());
        info.put("dbHost", getCachedDbHost(now));

        cachedServerInfo = info;
        cachedAtMillis = now;
        return cachedServerInfo;
    }

    private String getHostName() {
        try {
            return InetAddress.getLocalHost().getHostName();
        } catch (Exception e) {
            return "Error: " + e.getMessage();
        }
    }

    private String getServerIp() {
        try {
            return InetAddress.getLocalHost().getHostAddress();
        } catch (Exception e) {
            return "Error: " + e.getMessage();
        }
    }

    private String getAzureZone() {
        try {
            URL url = new URL(AZURE_METADATA_BASE_URL + "/compute/zone?api-version=2021-02-01&format=text");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setRequestProperty("Metadata", "true");
            conn.setConnectTimeout(METADATA_TIMEOUT_MILLIS);
            conn.setReadTimeout(METADATA_TIMEOUT_MILLIS);

            if (conn.getResponseCode() == 200) {
                try (Scanner scanner = new Scanner(conn.getInputStream(), "UTF-8").useDelimiter("\\A")) {
                    return scanner.hasNext() ? scanner.next() : "Unknown";
                }
            }
            return "N/A (Local/Non-Azure)";
        } catch (Exception e) {
            return "Error or Non-Azure: " + e.getMessage();
        }
    }

    private String getAwsZone() {
        String zone = getAwsMetadata("meta-data/placement/availability-zone");
        return valueOrDefault(zone, "N/A (Local/Non-AWS)");
    }

    private String detectCloudProvider() {
        if (getAwsMetadata("meta-data/placement/availability-zone") != null) {
            return "AWS";
        }

        String azureZone = getAzureZone();
        if (!azureZone.startsWith("Error") && !azureZone.startsWith("N/A")) {
            return "Azure";
        }

        return "Unknown";
    }

    private String getAwsMetadata(String path) {
        try {
            String token = getAwsMetadataToken();
            if (token == null) {
                return null;
            }

            URL url = new URL(AWS_METADATA_BASE_URL + "/" + path);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setRequestProperty("X-aws-ec2-metadata-token", token);
            conn.setConnectTimeout(METADATA_TIMEOUT_MILLIS);
            conn.setReadTimeout(METADATA_TIMEOUT_MILLIS);

            if (conn.getResponseCode() == 200) {
                try (Scanner scanner = new Scanner(conn.getInputStream(), "UTF-8").useDelimiter("\\A")) {
                    return scanner.hasNext() ? scanner.next() : null;
                }
            }
            return null;
        } catch (Exception e) {
            return null;
        }
    }

    private String getAwsMetadataToken() {
        try {
            URL url = new URL(AWS_METADATA_BASE_URL + "/api/token");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("PUT");
            conn.setRequestProperty("X-aws-ec2-metadata-token-ttl-seconds", "60");
            conn.setConnectTimeout(METADATA_TIMEOUT_MILLIS);
            conn.setReadTimeout(METADATA_TIMEOUT_MILLIS);

            if (conn.getResponseCode() == 200) {
                try (Scanner scanner = new Scanner(conn.getInputStream(), "UTF-8").useDelimiter("\\A")) {
                    return scanner.hasNext() ? scanner.next() : null;
                }
            }
            return null;
        } catch (Exception e) {
            return null;
        }
    }

    private String getCloudZone(String cloudProvider) {
        String configuredZone = System.getenv("CLOUD_ZONE");
        if (configuredZone != null && !configuredZone.isBlank()) {
            return configuredZone;
        }
        if ("AWS".equalsIgnoreCase(cloudProvider)) {
            return getAwsZone();
        }
        return "Azure".equalsIgnoreCase(cloudProvider) ? getAzureZone() : "N/A";
    }

    private String getDbHost() {
        try (Connection conn = dataSource.getConnection()) {
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT @@hostname")) {
                if (rs.next()) {
                    return rs.getString(1);
                }
            } catch (Exception ignored) {
                return conn.getMetaData().getURL();
            }
            return conn.getMetaData().getURL();
        } catch (Exception e) {
            return "Error: " + e.getMessage();
        }
    }

    private String getCachedDbHost(long now) {
        if (cachedDbHost != null && now - cachedDbHostAtMillis < DB_HOST_CACHE_TTL_MILLIS) {
            return cachedDbHost;
        }

        cachedDbHost = getDbHost();
        cachedDbHostAtMillis = now;
        return cachedDbHost;
    }

    private String valueOrDefault(String value, String defaultValue) {
        return value == null || value.isBlank() ? defaultValue : value;
    }

}
