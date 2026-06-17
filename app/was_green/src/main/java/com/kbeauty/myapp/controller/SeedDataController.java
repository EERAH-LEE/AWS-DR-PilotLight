package com.kbeauty.myapp.controller;

import java.util.Map;

import javax.sql.DataSource;

import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class SeedDataController {

    private final DataSource dataSource;

    public SeedDataController(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @GetMapping("/insert")
    public Map<String, String> insertByGet() {
        runSeedProductsSql();
        return Map.of("message", "seed-products.sql executed");
    }

    @PostMapping("/insert")
    public Map<String, String> insertByPost() {
        runSeedProductsSql();
        return Map.of("message", "seed-products.sql executed");
    }

    private void runSeedProductsSql() {
        ResourceDatabasePopulator populator = new ResourceDatabasePopulator();
        populator.addScript(new ClassPathResource("db/seed-products.sql"));
        populator.execute(dataSource);
    }
}
