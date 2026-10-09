import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { MENSAJES } from "../../src/mensajes";
import {
  idRestaurante,
  normalizarNombreRestaurante,
} from "../../src/normalizacion";
import { validarRegistro } from "../../src/validaciones";

const VALIDOS = {
  nombres: "  Camila ",
  apellidos: "Ruiz   Gómez",
  correo: " Camila@Correo.com ",
  restaurante: "  Sábor   Casero ",
  contrasena: "Cocina12",
};

describe("validarRegistro", () => {
  it("acepta datos válidos y los deja limpios", () => {
    assert.deepEqual(validarRegistro(VALIDOS), {
      ok: true,
      datos: {
        nombres: "Camila",
        apellidos: "Ruiz Gómez",
        correo: "camila@correo.com",
        restaurante: "Sábor Casero",
        restauranteNormalizado: "sabor casero",
        contrasena: "Cocina12",
      },
    });
  });

  it("CA2: marca todos los campos cuando llega vacío o sin objeto", () => {
    for (const entrada of [{}, null, undefined, "texto", 42]) {
      const resultado = validarRegistro(entrada);
      assert.equal(resultado.ok, false);
      if (!resultado.ok) {
        assert.deepEqual(resultado.errores, {
          nombres: MENSAJES.campoObligatorio,
          apellidos: MENSAJES.campoObligatorio,
          restaurante: MENSAJES.campoObligatorio,
          correo: MENSAJES.campoObligatorio,
          contrasena: MENSAJES.campoObligatorio,
        });
      }
    }
  });

  it("CA2: rechaza campos con solo espacios o que no son texto", () => {
    const resultado = validarRegistro({
      ...VALIDOS,
      nombres: "   ",
      apellidos: 7,
    });
    assert.equal(resultado.ok, false);
    if (!resultado.ok) {
      assert.deepEqual(resultado.errores, {
        nombres: MENSAJES.campoObligatorio,
        apellidos: MENSAJES.campoObligatorio,
      });
    }
  });

  it("CA4: rechaza correos con formato no válido", () => {
    for (const correo of [
      "camila",
      "camila@correo",
      "cami la@correo.com",
      "cami..la@correo.com",
    ]) {
      const resultado = validarRegistro({ ...VALIDOS, correo });
      assert.equal(resultado.ok, false, correo);
      if (!resultado.ok) {
        assert.equal(resultado.errores.correo, MENSAJES.correoInvalido);
      }
    }
  });

  it("CA6: rechaza contraseñas débiles", () => {
    for (const contrasena of ["Cocina1", "cocina123", "COCINA123", "CocinaRica"]) {
      const resultado = validarRegistro({ ...VALIDOS, contrasena });
      assert.equal(resultado.ok, false, contrasena);
      if (!resultado.ok) {
        assert.equal(resultado.errores.contrasena, MENSAJES.contrasenaDebil);
      }
    }
  });
});

describe("normalización del restaurante (CA10)", () => {
  it("coincide con las reglas de la app", () => {
    assert.equal(
      normalizarNombreRestaurante("  SÁBOR   CASERO "),
      "sabor casero",
    );
    assert.equal(normalizarNombreRestaurante("La Peña"), "la peña");
    assert.equal(
      normalizarNombreRestaurante("ÁÉÍÓÚ áéíóú Ü"),
      "aeiou aeiou u",
    );
  });

  it("el mismo nombre normalizado da el mismo id de restaurante", () => {
    const a = idRestaurante(normalizarNombreRestaurante("Sabor Casero"));
    const b = idRestaurante(normalizarNombreRestaurante("  sábor  CASERO"));
    const c = idRestaurante(normalizarNombreRestaurante("Sabor Casero 2"));
    assert.equal(a, b);
    assert.notEqual(a, c);
    assert.match(a, /^[0-9a-f]{64}$/);
  });
});
