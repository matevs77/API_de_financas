package com.financas.api.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

/**
 * Configuração OpenAPI (springdoc) e classe de arranque do projecto.
 *
 * Nota: a classe fica aqui para evitar criar ficheiros adicionais fora do solicitado.
 */
@SpringBootApplication(scanBasePackages = "com.financas.api")
public class OpenApiConfig {

    public static void main(String[] args) {
        SpringApplication.run(OpenApiConfig.class, args);
    }

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Finanças Pessoais API")
                        .version("0.0.1"));
    }
}

