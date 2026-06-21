<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageQuickFacts\Services\CreateQuickFact;
use App\Domains\Contact\ManageQuickFacts\Services\DestroyQuickFact;
use App\Domains\Contact\ManageQuickFacts\Services\ToggleQuickFactModule;
use App\Domains\Contact\ManageQuickFacts\Services\UpdateQuickFact;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Quick facts
 */
class ContactQuickFactApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        (new CreateQuickFact)->execute($this->baseData($request, $vaultId, $contactId) + [
            'vault_quick_facts_template_id' => $request->input('vault_quick_facts_template_id'),
            'content' => $request->input('content'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function update(Request $request, string $vaultId, string $contactId, string $quickFactId)
    {
        (new UpdateQuickFact)->execute($this->baseData($request, $vaultId, $contactId) + [
            'quick_fact_id' => (int) $quickFactId,
            'content' => $request->input('content'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $quickFactId)
    {
        (new DestroyQuickFact)->execute($this->baseData($request, $vaultId, $contactId) + [
            'quick_fact_id' => (int) $quickFactId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    /**
     * Toggle whether quick facts are shown for this contact.
     */
    public function toggle(Request $request, string $vaultId, string $contactId)
    {
        (new ToggleQuickFactModule)->execute($this->baseData($request, $vaultId, $contactId));

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
