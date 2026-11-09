INSERT INTO store_categories (code, name, description, image_url, created_by, updated_by)
VALUES
  ('abarrotes', 'Abarrotes', 'Productos básicos del hogar', NULL, NULL, NULL),
  ('comida', 'Comida', 'Comida preparada y antojitos', NULL, NULL, NULL)
ON CONFLICT (code) DO NOTHING;

INSERT INTO product_units (code, name, description, created_by, updated_by)
VALUES
  ('pieza', 'Pieza', 'Unidad por pieza', NULL, NULL),
  ('kg', 'Kilogramo', 'Unidad por kilogramo', NULL, NULL)
ON CONFLICT (code) DO NOTHING;
