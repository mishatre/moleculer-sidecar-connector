////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Ordinary-application form: refuses to run the installer.

Процедура ПередОткрытием(Отказ, СтандартнаяОбработка)
	Отказ = Истина;
	Предупреждение("Установщик не поддерживает обычное приложение. Используйте управляемое приложение.");
КонецПроцедуры
