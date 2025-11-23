package com.synopsis.OauthServer.oauth;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;
import org.springframework.security.oauth2.server.authorization.settings.AuthorizationServerSettings;
import org.springframework.security.web.SecurityFilterChain;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class SecurityConfigTest {

    @Autowired
    private RegisteredClientRepository registeredClientRepository;

    @Autowired
    private UserDetailsService userDetailsService;

    @Autowired
    private AuthorizationServerSettings authorizationServerSettings;

    @Autowired
    private List<SecurityFilterChain> filterChains;

    @Test
    void registeredClientIsConfigured() {
        RegisteredClient client = registeredClientRepository.findByClientId("gateway-client");

        assertThat(client).isNotNull();
        assertThat(client.getRedirectUris()).contains("http://localhost:8000/login/oauth2/code/gateway-client");
        assertThat(client.getScopes()).contains("products.read", "products.write");
    }

    @Test
    void userDetailsServiceExposesConfiguredUser() {
        UserDetails userDetails = userDetailsService.loadUserByUsername("miguelotech");

        assertThat(userDetails).isNotNull();
        assertThat(userDetails.getUsername()).isEqualTo("miguelotech");
        assertThat(userDetails.getPassword()).contains("926100349");
        assertThat(userDetails.getAuthorities()).isNotEmpty();
    }

    @Test
    void authorizationServerSettingsHaveIssuerConfigured() {
        assertThat(authorizationServerSettings.getIssuer()).isEqualTo("http://localhost:9050");
    }

    @Test
    void bothSecurityFilterChainsAreLoaded() {
        assertThat(filterChains).hasSize(2);
    }
}
