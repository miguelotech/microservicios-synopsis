package com.synopsis.OauthServer;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class OauthServiceApplicationTests {

	@Test
	void applicationClassIsLoadable() {
		assertThat(new OauthServiceApplication()).isNotNull();
	}
}
